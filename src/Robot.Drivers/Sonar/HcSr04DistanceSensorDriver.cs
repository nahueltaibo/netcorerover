﻿using System;
using System.Threading;
using System.Threading.Tasks;
using Iot.Device.Hcsr04;
using Microsoft.Extensions.Logging;

namespace Robot.Drivers.Sonar
{
    public class HcSr04DistanceSensorDriver : IDistanceSensor
    {
        private readonly Hcsr04 _sensor;
        private static readonly object SyncRoot = new object();

        public int Id { get; }
        public double Angle { get; }
        private CancellationTokenSource MeasuringCancellationToken { get; set; }
        private HcSr04DistanceSensorDriverSettings Settings { get; }
        private ILogger<HcSr04DistanceSensorDriver> Logger { get; }

        public event EventHandler<SonarDistanceEventArgs> SonarDistanceChanged;

        public HcSr04DistanceSensorDriver(HcSr04DistanceSensorDriverSettings settings,
            ILogger<HcSr04DistanceSensorDriver> logger)
        {
            Id = settings.SensorId;
            Angle = settings.Angle;
            _sensor = new Hcsr04(settings.TriggerPin, settings.EchoPin);
            MeasuringCancellationToken = new CancellationTokenSource();
            Task.Run(() => MeasurementCycle());
            Settings = settings;
            Logger = logger;
        }

        private async Task MeasurementCycle()
        {
            var token = MeasuringCancellationToken.Token;
            while (!token.IsCancellationRequested)
            {
                var interval = Task.Delay(Settings.MeasuringInterval);
                var measurement = DoMeasurement();
                await Task.WhenAll(interval, measurement);
            }
        }

        private Task DoMeasurement()
        {
            return Task.Run(() =>
            {
                try
                {
                    if (SonarDistanceChanged != null)
                    {
                        double? measurement;

                        // Now we're entering a critical section to avoid sonar interference
                        // Sound wave from one sonar may affect the another's results
                        lock (SyncRoot)
                        {
                            measurement = _sensor.Distance / 100; // Convert from cm to m
                        }

                        SonarDistanceChanged.Invoke(this, new SonarDistanceEventArgs
                        {
                            SonarId = Id,
                            Angle = Angle,
                            Distance = measurement
                        });
                    }
                }
                catch (Exception e)
                {
                    Logger.LogError(e, "Sonar {0} failed to raise a SonarDistanceChanged event", Id);
                }
            });
        }

        ~HcSr04DistanceSensorDriver()
        {
            Dispose(false);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
            if (disposing)
            {
                // ReSharper disable once InconsistentlySynchronizedField
                _sensor.Dispose();
                MeasuringCancellationToken.Cancel();
            }
        }
    }
}
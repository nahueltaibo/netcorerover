﻿using System;
using System.Threading.Tasks;

namespace MessageBus
{
    public interface IMessageBroker
    {
        Task PublishAsync<T>(T message) where T : IMessage;

        Task SubscribeAsync<T>(Action<IMessage> callback) where T : IMessage;
    }
}
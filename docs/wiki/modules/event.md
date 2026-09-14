# Module: `event`

`internal/event` provides typed publish/subscribe delivery for lifecycle and server events.

## Key file

- [`event.go`](../../../internal/event/event.go) — dispatcher, generic subscriptions, consumer queues, and groups.

## Public surface

`NewDispatcher` and `NewDispatcherConfig` create dispatchers. `Subscribe` infers an event type from a generic event, `SubscribeTo` accepts an explicit type, `Publish` broadcasts, and `Dispatcher.Close` stops delivery.

## Concurrency

Subscriber registries are immutable snapshots behind an atomic pointer. Writers use a mutex; event consumers process queue batches outside the condition-variable critical section. Each consumer has a bounded queue and backpressure behavior.

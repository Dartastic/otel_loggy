# otel_loggy

OpenTelemetry log bridge for
[`package:loggy`](https://pub.dev/packages/loggy).

Mirrors every Loggy record into the OpenTelemetry logs pipeline so
structured records flow to your OTel backend while Loggy keeps
rendering. Records inherit `trace_id` / `span_id` from the active
span — log calls inside a `Tracer.startActiveSpan` block are
auto-correlated.

## Install

```yaml
dependencies:
  loggy: ^2.0.2
  otel_loggy: ^0.2.0
```

## Use

```dart
import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:loggy/loggy.dart';
import 'package:otel_loggy/otel_loggy.dart';

Future<void> main() async {
  await OTel.initialize(
    serviceName: 'my-app',
  );

  Loggy.initLoggy(
    logPrinter: const OTelLoggyPrinter(),
    logOptions: const LogOptions(LogLevel.all),
  );

  logInfo('user signed in');
  logError('boom', StateError('out of stock'), StackTrace.current);
}
```

To also keep Loggy's own pretty-printer in the console, combine printers:

```dart
Loggy.initLoggy(
  logPrinter: const MultiPrinter([
    PrettyPrinter(),
    OTelLoggyPrinter(),
  ]),
);
```

## Severity mapping

| Loggy `LogLevel` | OTel `severity_number` |
|------------------|------------------------|
| `all`            | `TRACE`                |
| `debug`          | `DEBUG`                |
| `info`           | `INFO`                 |
| `warning`        | `WARN`                 |
| `error`          | `ERROR`                |
| `off`            | `UNSPECIFIED`          |
| (other)          | `INFO`                 |

## Suppression

```dart
runWithoutLoggyInstrumentation(() {
  logInfo('not exported to OTel');
});
```

## License

Apache 2.0 — copyright Mindful Software LLC.

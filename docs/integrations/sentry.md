# Sentry Integration

Sentry is an error tracking platform for tracking your application's exceptions.

The Sentry integration sends errors from DataDuck ETL to Sentry. Errors while ETLing a table will not stop other tables from still working.

To use the Sentry integration, add your Sentry DSN to your .env file:

```
SENTRY_DSN=123456
```

Now errors will be sent to Sentry automatically.

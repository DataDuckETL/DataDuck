# Airbrake Integration

Airbrake is an error tracking platform for tracking your application's exceptions.

The Airbrake integration uses Airbrake's API to send errors to Airbrake. Errors while ETLing a table will not stop other tables from still working.

To use the Airbrake integration, add your project id and project key to your .env file:

```
AIRBRAKE_PROJECT_ID=123456
AIRBRAKE_PROJECT_KEY=abcdefghijklmnopqrstuvwxyz
```

Now errors will be sent to Airbrake automatically.

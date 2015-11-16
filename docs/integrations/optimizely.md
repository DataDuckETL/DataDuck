# Optimizely Integration

Optimizely is a website optimization platform which includes a/b testing and personalization products.

The Optimizely integration uses Optimizely's API to fetch data for your projects, experiments, and variations, then puts them into
three tables in your data warehouse.

To use the Optimizely integration, first, get an API token from [https://app.optimizely.com/tokens](https://app.optimizely.com/tokens). Then add the following to your project's .env file:

```
optimizely_api_token=YOUR_TOKEN
```

Finally, add the following file to your project's /src/tables directory, naming it optimizely_integration.rb

```ruby
class OptimizelyIntegration < DataDuck::Optimizely::OptimizelyIntegration
end
```

Now, running `dataduck etl optimizely_integration` will ETL three tables for you. These tables are `optimizely_projects`, `optimizely_experiments`, and `optimizely_variations`. The results data can be found on the variations. Additionally, a `dataduck_extracted_at` datetime column indicates how fresh the data is.

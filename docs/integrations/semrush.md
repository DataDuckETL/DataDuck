# SEMrush Integration

SEMrush is a powerful and versatile competitive intelligence suite for online marketing, from SEO and PPC to social media and video advertising research.

The SEMrush integration is currently focused on SEO. It will create a table called `semrush_organic_results` that shows the Google search ranking for specific phrases. By running this regularly, you can see how your website or your competitors' websites search rankings change over time.

To use the SEMrush integration, first add the following to your .env file:

```
semrush_api_key=YOUR_API_KEY
```

Then create a table called `organic_results` with the following:

```ruby
class OrganicResults < DataDuck::SEMRush::OrganicResults
  def display_limit
    20 # Default is 20
  end

  def search_database
    'us' # Default is 'us'
  end

  def phrases
    ['My Phrase 1',
      "Another Phrase",
      "Some Other Keywords",
    ]
  end
end
```

This table will have five columns: date, phrase, rank, domain, and url.

The methods display_limit and search_database are optional, but can be modified to fit your particular use case.

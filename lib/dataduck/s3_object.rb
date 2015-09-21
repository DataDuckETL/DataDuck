require 'aws-sdk'

module DataDuck
  class S3Object
    def initialize(path, contents, aws_key, aws_secret, bucket, region, options={})
      @path = path
      @contents = contents
      @options = options
      @aws_key = aws_key
      @aws_secret = aws_secret
      @bucket = bucket
      @region = region
    end

    def upload!
      s3 = Aws::S3::Client.new(
          region: @region,
          access_key_id: @aws_key,
          secret_access_key: @aws_secret,
      )

      attempts = 0

      while attempts <= S3Object.max_retries
        attempts += 1
        put_hash = @options.merge({
                acl: 'private',
                bucket: @bucket,
                body: @contents,
                key: self.full_path,
                server_side_encryption: 'AES256',
            })
        begin
          response = s3.put_object(put_hash)
        rescue Exception => e
          if attempts == S3Object.max_retries
            throw e
          end
        end
      end

      response
    end

    def full_path
      'dataduck/' + @path
    end

    def s3_path
      "s3://#{ @bucket }/#{ full_path }"
    end

    def self.max_retries
      3
    end

    def self.regions
      [
          { name: 'US Standard - N. Virginia', region: 'us-east-1' },
          { name: 'US West - N. California', region: 'us-west-1' },
          { name: 'US West - Oregon', region: 'us-west-2' },
          { name: 'EU - Ireland', region: 'eu-west-1' },
          { name: 'EU - Frankfurt', region: 'eu-central-1' },
          { name: 'Asia Pacific - Singapore', region: 'ap-southeast-1' },
          { name: 'Asia Pacific - Sydney', region: 'ap-southeast-2' },
          { name: 'Asia Pacific - Tokyo', region: 'ap-northeast-1' },
          { name: 'South America - Sao Paulo', region: 'sa-east-1' },
      ]
    end
  end
end

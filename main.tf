# Primary S3 bucket with website enabled

provider "aws" {
	region = "us-east-1"
}

locals {
	s3_origin_id = "LLWbrDpSP8"
	oai	= "ABCDEFG1234567"
}

data "template_file" "b-bucketpolicy" {
	template = "${file("tpl/bucketpolicy.tpl")}"
	vars {
		origin_access_identity = "${local.oai}"
	}
}

resource "aws_s3_bucket" "b" {
  bucket = "shortener.darkuniverse.xyz"
  acl    = "public-read"
	# policy = "${data.template_file.b-bucketpolicy.rendered}"
	
	website {
		index_document = "index.html"
		error_document = "error.html"
	}
  tags = {
    Name = "shortener.darkuniverse.xyz"
  }
}

resource "aws_cloudfront_origin_access_identity" "oai_default" {
  comment = "Some comment"
}

resource "aws_cloudfront_distribution" "cdn" {
	origin {
		domain_name = "${aws_s3_bucket.b.bucket_regional_domain_name}"
		origin_id = "${local.s3_origin_id}"
		
		s3_origin_config {
			origin_access_identity = "${aws_cloudfront_origin_access_identity.oai_default.cloudfront_access_identity_path}"
		}
	}

	enabled = true
	default_root_object = "index.html"
	
	aliases = ["shortener.darkuniverse.xyz"]
	
	default_cache_behavior {
		allowed_methods	= ["GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT", "DELETE"]
		cached_methods = ["GET", "HEAD"]
		target_origin_id = "${local.s3_origin_id}"
		
		forwarded_values {
			query_string = true
			cookies {
				forward = "all"
			}
		}
		viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
	}
	restrictions {
		geo_restriction {
			restriction_type = "whitelist"
			locations	= ["US"]
		}
	}
	tags = {
		Name = "shortener.darkuniverse.xyz"
	}

	viewer_certificate {
		acm_certificate_arn = "arn:aws:acm:us-east-1:996074140793:certificate/be5825c6-288a-4fdc-b250-69b4b7e2b246"
		ssl_support_method = "sni-only"
  }
}

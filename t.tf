provider "aws" {
  region     = "ap-south-1"
  profile = "Punit"

}


resource "aws_key_pair" "keygen" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"

}

resource "aws_ebs_volume" "ebs_volume1" {
  availability_zone = "${aws_instance.instance_ec2.availability_zone}"
  size              = 1

  tags = {
    Name = "ebs_volume1"
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allows http and ssh"
  vpc_id      = "${aws_vpc.main.id}"


  ingress {
    description = "HTTP allow"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "allow_HTTP"
  }
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "uniquenessisanillusion"
  force_destroy = true
  acl    = "public-read"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "MYBUCKETPOLICY",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::uniquenessisanillusion/*"
    }
  }
}
POLICY





resource "aws_s3_bucket_object" "object" {
  bucket = "uniquenessisamyth"
  key    = "photo.jpg"
  source = "C:/Users/punit/Desktop/image/img.jpg"
  etag = "C:/Users/punit/Desktop/image/img.jpg"
depends_on = [aws_s3_bucket.bucket1,
		]
}


output "test1" {
  value = "aws_security_grp.allow_http"
  }


resource "aws_instance" "instance_ec2" {
depends_on = [aws_key_pair.keygen,
	        aws_security_group.allow_http,
		]


  ami      = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "me"
  security_groups = ["allow_http"]
  tags = {
    Name = "OS1"
  }

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/punit/Documents/task/keys/myprivatekey.pem")
    host     = "${aws_instance.instance_ec2.public_ip}"
  }

provisioner "remote-exec"  {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",

    ]
  }


}


resource "aws_volume_attachment" "ebs_att" {
  depends_on = [aws_ebs_volume.ebs_volume1,
		aws_instance.instance_ec2,
		]


  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.ebs_volume1.id}"
  instance_id = "${aws_instance.instance_ec2.id}"



}

resource "null_resource" "null1" {

depends_on = [aws_volume_attachment.ebs_att,
		]
    connection {
    	type     = "ssh"
    	user     = "ec2-user"
    	private_key = file("C:/Users/punit/Documents/task/keys/myprivatekey.pem")
    	host     = "${aws_instance.instance_ec2.public_ip}"
  }
	provisioner "remote-exec"  {
		inline = [
     		"sudo mkfs.ext4  /dev/xvdh",
      		"sudo mount  /dev/xvdh  /var/www/html",
      		"sudo rm -rf /var/www/html/*",
      		"sudo git clone https://github.com/vimallinuxworld13/multicloud.git /var/www/html/"
    ]
  }


}




resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.bucket1.bucket_regional_domain_name}"
    origin_id   = "s3-bucket1-bucket"
    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/ABCDEFG1234567"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "mylogs.s3.amazonaws.com"
    prefix          = "myprefix"
  }

  aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-bucket1-bucket"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "s3-bucket1-bucket"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-bucket1-bucket"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
}

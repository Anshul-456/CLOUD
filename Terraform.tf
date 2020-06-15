#generate keypair
resource "aws_key_pair" "mykey" {

  key_name   = "mykey456"

  public_key = "ssh-rsa BBBAB3NzaC1yc2EAAAABJQAAAQEAkauEK+LUSXMp8VnyfTNL6N/VT5W1sjW1mQyy+1C6uzqN4ybkFerRAZIqDU7ghidhMDyT+FjJ/+cgUcmq7e1qpQKy/ejCDkpALJv8OcWkBXiih7IkSL6dKQ7arPhPSKK1hEHfMt2dG4JdSc4LTI+WMptCHicT5KbTPLISUzf6Ris6ISxDul04bexTC0at9gHjdxCC3bdP22STWveKle0bUYz31ybbgXjLwMo8UWrZxFxjaqGxXTlpzvkBfeB1o4JDWBW2FmNder05+/etGLgbSyXZbh2T8m9PRkQNZ2IjqLrWNeUTcbSWGrUwVHcigMT9SLKfQhL8Td4ajL5e9PE6yQ== rsa-key-20200615"
}

provider "aws" {
	region = "ap-south-1"
	profile = "anshul"
}

#creating a security_group
resource "aws_security_group" "security_group1" {
  name        = "security_group1"
  description = "Allow Tcp & ssh inbound traffic"
  vpc_id      = "vpc-5a595432"
  


  ingress {

    description = "Ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {

    description = "http"
    from_port   = 80
    to_port     = 80
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

    Name = "allow_SSh_http"
  }
}

provider "aws" {
  
  region = "ap-south-1"
  profile = "anshul"
}


variable "mykey" {

	type = string
	default = "mykey456"
}


#creating an aws instance 

resource "aws_instance" "inst" {

  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name      = var.mykey
  security_groups = [ "security_group1" ]
  




  connection {

    type     = "ssh"
    user     = "ec2-user"
    private_key = file    ("C:\Users\KIIT\Desktop\aws\mykey456.pem")
    host     = aws_instance.inst.public_ip
  }


  
  provisioner "remote-exec" {

    inline = [

      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }
  
  tags = {

    Name = "anshul"
  }
}


output "avail_zone" {

	value = aws_instance.inst.availability_zone
}


output "Vol_id" {

	value = aws_ebs_volume.myvol1.id
}


output "inst_id" {

	value = aws_instance.inst.id
}

#launching ebs
resource "aws_ebs_volume" "myvol1" {

  availability_zone = aws_instance.inst.availability_zone
  size              = 1


 tags = {

    Name = "My_volume"
  }
}




resource "aws_volume_attachment" "ebs_att" {

  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.myvol1.id}"
  instance_id = "${aws_instance.inst.id}"
  force_detach = true

}


resource "null_resource" "nullremote3"  {


depends_on = [
    aws_volume_attachment.ebs_att,
  ]


 connection {

    type     = "ssh"
    user     = "ec2-user"
    private_key = file    ("C:\Users\KIIT\Desktop\aws\mykey456.pem")
    host     = aws_instance.inst.public_ip
 
 }


provisioner "remote-exec" {

    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/anshul-456/CLOUD.git /var/www/html/"
    ]
  }
}

resource "null_resource" "nullremote2"  {


depends_on = [

    null_resource.nullremote3,
  ]


provisioner "local-exec" {

	    command = "start chrome  ${aws_instance.inst.public_ip}"
  	}
}


resource "aws_s3_bucket" "bucket" {

  bucket = "my-website-test-bucket"
  acl    = "public-read"


  tags = {

    Name        = "My bucket"
    
  }
  force_destroy = true


provisioner "local-exec" {

        command     = "git clone https://github.com/anshul-456/image  images"
    }
provisioner "local-exec" {

        when        =   destroy
        command     =   "echo Y | rmdir /s images"
    }
}
resource "aws_s3_bucket_object" "image-upload" {

    bucket  = aws_s3_bucket.bucket.bucket
    key     = "mypic1"
    source  = "images/matchfinished.png"
    acl     = "public-read"
}




locals {

  s3_origin_id = "mys3origin"
 image_url = "${aws_cloudfront_distribution.s3_distribution.domain_name}/${aws_s3_bucket_object.image-upload.key}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {

  default_cache_behavior {


    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
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


 enabled             = true


  origin {

    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id


   
  }


  restrictions {

    geo_restriction {

      restriction_type = "none"
    }
  }




  viewer_certificate {

    cloudfront_default_certificate = true
  }




connection {
        type    = "ssh"
        user    = "ec2-user"
        host    = aws_instance.inst.public_ip
        port    = 22
        private_key = file    ("C:\Users\KIIT\Desktop\aws\mykey456.pem")
    }
provisioner "remote-exec" {

        inline  = [

            # "sudo su << \"EOF\" \n echo \"<img src='${self.domain_name}'>\" >> /var/www/html/index.html \n \"EOF\""
            "sudo su << EOF",
            "echo \"<img src='http://${self.domain_name}/${aws_s3_bucket_object.image-upload.key}'>\" >> /var/www/html/index.html",
            "EOF"
        ]
    }
}


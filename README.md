# Performance-Testing-Automation-Perl-JMeter
Automated web application performance testing using Perl and JMeter

## Introduction
The whole idea behind this is to execute multiple performance tests script files without human intervention.
As performance testing scripts take lot of time to execute. This setup will make sure that they are executed with given
test configuration and user receives execution report at the end.
With this setup, user can set this as a scheduled job to run these cases.

## Get Started
1. Clone this repo
2. Copy `.jmx` files to `input` directory
3. Edit and update `script/config.properties` and `config.properties` files
4. Update `inputs.xml` file with specify which `.jmx` scripts to execute
5. Edit and update `Run.sh` file with `JMeter` home directory
6. Run `Run.sh` file

## Author
[Vikas Sanap](https://www.linkedin.com/in/vikassanap/)

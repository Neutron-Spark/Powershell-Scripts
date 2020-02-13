## Purpose
Uses DiskSpd.exe and a test .dat file to test the throughput and performance of the C:\ drive. The results of the test are recorded to a log file and an average calculated. If the result is below a certain amount than an email is sent to DESITNATION_ADDRESS detailing the decrease in throughput.

## Known Issues
* Averaging may be skewed in the first few runs

## Restrictions
* Requires the file 'TestFile.dat' to have been made and in the correct folder

## Example Output
```
01/10/2017 12:00:01 Starting Disk Test
01/10/2017 12:00:01 Starting Disk Benchmark
01/10/2017 12:01:03 Average past throughput is 18.0833333333333 MB/s
01/10/2017 12:01:03 Latest result is 1.23 MB/s
01/10/2017 12:01:03 -1,370.19% decrease in speed
01/10/2017 12:01:03 WARNING - MASSIVE DECREASE IN THROUGHPUT
01/10/2017 12:01:03 Sending Email.... 
```

## Important Notes
* This is an archived script and may not work
* This requires the .exe to be in the same folder as the script
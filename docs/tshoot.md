# Troubleshooting section

## Rate limiting issues

* Issue:

Rate limiting in DockerHub sometimes prevent to pull the images if your cluster reach the DockerHub limit.

For example:

```
Failed to pull image "centos": rpc error: code = Unknown desc = Error reading manifest latest in
docker.io/library/centos: toomanyrequests: You have reached your pull rate limit. You may increase
the limit by authenticating and upgrading:
```

* Resolution:

To prevent this you can [authenticate your docker hub
account](https://developers.redhat.com/blog/2021/02/18/how-to-work-around-dockers-new-download-rate-limit-on-red-hat-openshift#authenticate_to_your_docker_hub_account)

On the other hand, we'll move all the images to quay.io / registry.redhat.io to prevent this issue.

## Code Analysis Failures

* Issue:

Sometimes Code Analysis raises an error when mvn is running the maven install 'sonar:sonar':

```
[[1;31mERROR[m] Failed to execute goal
[32morg.apache.maven.plugins:maven-compiler-plugin:3.8.1:testCompile[m [1m(default-testCompile)[m on
project [36mspring-petclinic[m: [1;31mCompilation failure[m
[[1;31mERROR[m]
[1;31m/workspace/source/spring-petclinic/src/test/java/org/springframework/samples/petclinic/service/ClinicServiceTests.java:[30,51]
cannot access org.springframework.samples.petclinic.owner.Pet[m
[[1;31mERROR[m] [1;31m  bad class file:
/workspace/source/spring-petclinic/target/classes/org/springframework/samples/petclinic/owner/Pet.class[m
[[1;31mERROR[m] [1;31m    class file contains wrong class:
org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest[m
[[1;31mERROR[m] [1;31m    Please remove or make sure it appears in the correct subdirectory of the
classpath.[m
[[1;31mERROR[m] [1;31m[m
[[1;31mERROR[m] -> [1m[Help 1][m
[[1;31mERROR[m]
```

* Resolution:

Just rerun the pipeline and will succeed without changing anything additional. The results will
succeed afterwards:

```
[[1;34mINFO[m] Analyzed bundle 'petclinic' with 20 classes
[[1;34mINFO[m]
[[1;34mINFO[m] [1m--- [0;32mmaven-jar-plugin:3.1.2:jar[m [1m(default-jar)[m @
[36mspring-petclinic[0;1m ---[m
[[1;34mINFO[m]
[[1;34mINFO[m] [1m--- [0;32mspring-boot-maven-plugin:2.2.5.RELEASE:repackage[m [1m(repackage)[m @
[36mspring-petclinic[0;1m ---[m
[[1;34mINFO[m] Replacing main artifact with repackaged archive
[[1;34mINFO[m] [1m------------------------------------------------------------------------[m
[[1;34mINFO[m] [1;32mBUILD SUCCESS[m
[[1;34mINFO[m] [1m------------------------------------------------------------------------[m
[[1;34mINFO[m] Total time: 01:55 min
[[1;34mINFO[m] Finished at: 2021-07-23T07:37:09Z
[[1;34mINFO[m] Final Memory: 118M/1245M
[[1;34mINFO[m] [1m------------------------------------------------------------------------[m
```

## JUnit Tests Failures

Refer to the Code Analysis. Just rerun and it'll fix it.

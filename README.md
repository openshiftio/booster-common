# Common booster utilities

  
## Release process
  
1. `mvn release:prepare`
3. `git checkout $TAG`
4. `mvn clean deploy -Prelease`

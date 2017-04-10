# Common booster utilities

  
## Release process
  
1. `mvn release:prepare`
2. `git push origin master --tags`
3. `git checkout $TAG`
4. `mvn clean deploy -Prelease`

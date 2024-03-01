# Introduction

This example extends on the neon4cast example also in the FaaSr-examples repository. The neon4cast-split.json file uses a more complex workflow that distributes/parallelizes different sites across different actions. While in this particular example it may not lead to performance improvements, it shows the ability of FaaSr to create more complex workflows. To run it:

* Edit the neon4cast-split.json and replace the string <<YOUR_USER_NAME>> with your GitHub username, and save this file
* Register and run the workflow, following similar steps as above:

```
neon4cast-split <- faasr(json_path="neon4cast-split.json", env="env")
neon4cast-split$register_workflow()
```

When prompted, select "public" to create a public repository. Now run the workflow:

```
neon4cast-split$invoke_workflow()
```




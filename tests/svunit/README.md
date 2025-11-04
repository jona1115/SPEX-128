# Directory Organization

The way SVUnit read stuff is interesting. Tests are grouped into "test suites". See more [here](https://docs.svunit.org/en/latest/structure_and_workflow.html).

The way I set my project up:
1. From this location, each module has its own folder.
2. Inside each module folder are test suites.
3. There is a main "template" (language used in SVUnit docs) in each test suite. The name of the main template MUST end with "_unit_test". Same thing goes to the name of the `module` defined in each template.
4. The main template will `include` `.svh` files in the `cases` folder in its body.
5. The actual test code are located in the `.svh` files.

# SVUnit Tips:
Macros you can use to do tests
```sv
`define FAIL_IF(exp)
`define FAIL_UNLESS(exp)

`define FAIL_IF_EQUAL(a,b)
`define FAIL_UNLESS_EQUAL(a,b)

`define FAIL_IF_STR_EQUAL(a,b)
`define FAIL_UNLESS_STR_EQUAL(a,b)
```
For more see: [https://docs.svunit.org/en/latest/](https://docs.svunit.org/en/latest/)
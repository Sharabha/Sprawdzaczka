# Welcome to Sharabha!

##### Team project done at [Institute of Computer Science, University of Wrocław](http://www.ii.uni.wroc.pl) for Team Project Management Course 2011/2012

## Overview

###### Sharabha is designed to become online verifier system and environment for programming competitions.

Project is split into two independently deployed components:

- __Sharabha Portal__, based on [Ruby on Rails](http://www.rubyonrails.org)
- __Sharabha Checker__, based on [Erlang](http://www.erlang.org)

This is a repository of Sharabha Checker - a service for running solutions. It communicates with RESTful web API with Sharabha Portal.


## Checker README

#### Requirements:
- Erlang R15B (http://www.erlang.org)
- Riak database (http://wiki.basho.com/Installation.html)

#### Running project:
``$ cd Sprawdzaczka``

``$ make``

``$ make run``
or
``$ ./rel/sprawdzaczka/bin/sprawdzaczka console``

Check [http://localhost:8080/](http://localhost:8080/) (you should see hello world).

## License

###### Copyright 2012 [Institute of Computer Science, University of Wrocław](http://www.ii.uni.wroc.pl)

This project is licensed under the Apache License, Version 2.0 (the "License"). You may not use any of its files except in compliance with the License. You may obtain a copy of the License at [Apache home page](http://www.apache.org/licenses/LICENSE-2.0).

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
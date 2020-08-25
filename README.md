
        - Create a docker image and start the container running a pm2 react node.

        Usage:

                ./dockerize-project.pl -option <value>

        Options:

                -app-name [REQUIRED] String.  Directory path of the project you wish to dockerize.
                -nostart  [Optional] Flag.    Don't run the container after the build.
                -mode     [Optional] String.  Defaults to production.
                -port     [Optional] Int.     Defaults to 5000.

        Examples: 

                1) ./dockerize-project.pl -app-name appdir -nostart
                2) ./dockerize-project.pl -app-name appdir

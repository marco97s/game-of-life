# README

This Rails application provides basic authentication functionality, including email confirmation and account details modification.

Once authenticated, users can access the Game of Life. The game's main menu allows users to either start a new game by providing a game input file, or continue a previous game session. After uploading a valid game or resuming an existing game session, the application displays the current game state to the user, showing the current generation number and the matrix of live or dead cells using green and red rectangles. The application also provides start and stop buttons to automate the generation of game states.

Technical details:
* The authentication process is based on this tutorial: https://stevepolito.design/blog/rails-authentication-from-scratch
* Each generation follows these rules:
  * Any live cell with fewer than two live neighbours dies.
  * Any live cell with two or three live neighbours lives on to the next generation.
  * Any live cell with more than three live neighbours dies.
  * Any dead cell with exactly three live neighbours becomes a live cell.
* Any input file must be formatted like the following example:
```
Generation 3:
4 8
........
....*...
...**...
........
```
# rgbeam
This is an uglier version of [Guess my RGB](https://susam.net/myrgb.html) by Susam Pal. I made it to learn more about Gleam and Lustre.

You can play it [here](https://george-grec.github.io/rgbeam/) and this is what it looks like:

<img width="514" alt="image" src="https://github.com/george-grec/rgbeam/assets/28739561/c0b53e4a-7ab2-426f-8bee-34e63845ad38">



## Development

```sh
gleam build
gleam run -m lustre/dev start --use-example-styles # Run the project
```

## Bundle
```sh
gleam run -m esgleam/bundle
```

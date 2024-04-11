import lustre
import lustre/effect.{type Effect}
import gleam/int.{random}
import lustre/element.{type Element}
import lustre/element/html
import lustre/attribute
import lustre/ui
import gleam/io
import lustre/event
import gleam/result
import gleam/list
import gleam/float
import lustre/ui/layout/cluster

const steps = 16

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "body", Nil)
}

// MODEL ----------------------------------------------------------------------
pub opaque type Model {
  Model(actual: Rgb, current_guess: Rgb, guesses: List(Rgb))
}

type Rgb {
  Rgb(red: ColorValue, green: ColorValue, blue: ColorValue)
}

type ColorValue {
  ColorValue(value: Int)
}

fn to_base16_string(color: ColorValue) {
  int.to_base16(color.value)
}

fn to_float(color: ColorValue) -> Float {
  int.to_float(color.value)
}

fn init(_) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      actual: random_rgb(),
      guesses: [],
      current_guess: Rgb(ColorValue(8), ColorValue(8), ColorValue(8)),
    ),
    effect.none(),
  )
}

fn random_rgb() -> Rgb {
  let random_16 = fn() { ColorValue(random(steps)) }
  Rgb(red: random_16(), green: random_16(), blue: random_16())
}

// VIEW -----------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.body(
    [
      attribute.style([
        #("background", view_rgb(model.actual)),
        #("height", "100vh"),
        #("min-height", "100vh"),
        #("margin", "0"),
        #("padding", "0"),
      ]),
    ],
    [
      html.a([attribute.href("https://susam.net/myrgb.html")], [
        html.text("Original"),
      ]),
      html.text(", "),
      html.a([attribute.href("https://github.com/george-grec/rgbeam")], [
        html.text("Github"),
      ]),
      ui.centre(
        [],
        ui.prose([], [
          html.h1(
            [
              attribute.style([
                #("text-align", "center"),
                #("background-color", "#DDD"),
              ]),
            ],
            [html.text("Guess this RGB!")],
          ),
        ]),
      ),
      ui.centre(
        [],
        ui.stack([], [
          ui.cluster([cluster.loose()], {
            list.range(0, 15)
            |> list.map(int.to_base16)
            |> list.map(fn(x) { html.span([], [html.text(x)]) })
          }),
          view_slider(
            model.current_guess.red,
            UserChangedRed,
            view_rgb(Rgb(model.current_guess.red, ColorValue(0), ColorValue(0))),
          ),
          view_slider(
            model.current_guess.green,
            UserChangedGreen,
            view_rgb(Rgb(
              ColorValue(0),
              model.current_guess.green,
              ColorValue(0),
            )),
          ),
          view_slider(
            model.current_guess.blue,
            UserChangedBlue,
            view_rgb(Rgb(ColorValue(0), ColorValue(0), model.current_guess.blue)),
          ),
        ]),
      ),
      ui.centre(
        [],
        ui.stack([], [
          ui.button([event.on_click(UserGuessed)], [
            element.text("Submit " <> view_rgb(model.current_guess)),
          ]),
          ui.stack(
            [],
            list.zip(model.guesses, list.range(list.length(model.guesses), 1))
              |> list.map(view_guess(_, model.actual)),
          ),
        ]),
      ),
    ],
  )
}

fn view_slider(
  color: ColorValue,
  on_input: fn(String) -> Msg,
  accent_color: String,
) -> Element(Msg) {
  ui.input([
    attribute.type_("range"),
    attribute.min("0"),
    attribute.max("15"),
    attribute.width(50),
    attribute.value(int.to_string(color.value)),
    attribute.step("1"),
    attribute.style([#("accent-color", accent_color)]),
    event.on_input(on_input),
  ])
}

fn view_current_percent(current: Rgb, actual: Rgb) -> Int {
  let abs_red =
    float.absolute_value(to_float(actual.red) -. to_float(current.red))
  let abs_green =
    float.absolute_value(to_float(actual.green) -. to_float(current.green))
  let abs_blue =
    float.absolute_value(to_float(actual.blue) -. to_float(current.blue))
  {
    { { 16.0 -. abs_red } /. 16.0 }
    +. { { 16.0 -. abs_green } /. 16.0 }
    +. { { 16.0 -. abs_blue } /. 16.0 }
  }
  /. 3.0
  *. 100.0
  |> float.truncate
}

fn view_guess(guess_with_count: #(Rgb, Int), actual: Rgb) -> Element(Msg) {
  let #(guess, index) = guess_with_count
  let rgb_display = view_rgb(guess)

  ui.cluster([cluster.stretch(), cluster.align_centre()], [
    ui.box([attribute.style([#("background-color", "#DDD")])], [
      html.text(int.to_string(index) <> ") "),
      html.text(rgb_display <> " "),
      html.text(
        "(Accuracy: "
        <> { int.to_string(view_current_percent(guess, actual)) }
        <> "%)",
      ),
    ]),
    ui.box(
      [
        attribute.style([#("background-color", rgb_display)]),
        attribute.width(50),
      ],
      potential_win(guess, actual),
    ),
  ])
}

fn potential_win(guess: Rgb, actual: Rgb) -> List(Element(Msg)) {
  case guess == actual {
    False -> []
    True -> [html.text("Perfect match!")]
  }
}

fn view_rgb(color: Rgb) {
  "#"
  <> to_base16_string(color.red)
  <> to_base16_string(color.green)
  <> to_base16_string(color.blue)
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  UserGuessed
  UserChangedRed(String)
  UserChangedGreen(String)
  UserChangedBlue(String)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  let return = case msg {
    UserChangedRed(new_color) -> {
      let new_red = parse_color(new_color, fallback: model.current_guess.red)
      #(
        Model(..model, current_guess: Rgb(..model.current_guess, red: new_red)),
        effect.none(),
      )
    }

    UserChangedGreen(new_color) -> {
      let new_green =
        parse_color(new_color, fallback: model.current_guess.green)
      #(
        Model(
          ..model,
          current_guess: Rgb(..model.current_guess, green: new_green),
        ),
        effect.none(),
      )
    }

    UserChangedBlue(new_color) -> {
      let new_blue = parse_color(new_color, fallback: model.current_guess.blue)
      #(
        Model(
          ..model,
          current_guess: Rgb(..model.current_guess, blue: new_blue),
        ),
        effect.none(),
      )
    }

    UserGuessed -> #(
      Model(..model, guesses: [model.current_guess, ..model.guesses]),
      effect.none(),
    )
  }

  io.debug(return.0)

  return
}

fn parse_color(raw_value: String, fallback fallback: ColorValue) -> ColorValue {
  int.parse(raw_value)
  |> result.map({ ColorValue(_) })
  |> result.unwrap(fallback)
}

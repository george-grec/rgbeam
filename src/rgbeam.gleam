import gleam/float
import gleam/int.{random}
import gleam/list
import gleam/result
import gleam_community/colour.{type Color}
import gleam_community/colour/accessibility
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "body", Nil)
}

// MODEL ----------------------------------------------------------------------
pub opaque type Model {
  Model(actual: Color, current_guess: Color, guesses: List(Color))
}

type BasicColor {
  Red
  Green
  Blue
}

fn init(_) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      actual: random_color(),
      guesses: [],
      current_guess: force_color_from_rgb255(8 * 16, 8 * 16, 8 * 16),
    ),
    effect.none(),
  )
}

fn force_color_from_rgb255(red: Int, green: Int, blue: Int) -> Color {
  let assert Ok(color) = colour.from_rgb255(red, green, blue)
  color
}

fn random_color() -> Color {
  let random_color_255 = fn() {
    let rand = random(16)
    rand * 16 + rand
  }

  force_color_from_rgb255(
    random_color_255(),
    random_color_255(),
    random_color_255(),
  )
}

// VIEW -----------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.body(
    [
      attribute.style([#("background", view_color(model.actual))]),
      attribute.class(
        "flex flex-col items-center justify-start m-0 p-0 h-screen min-h-screen",
      ),
    ],
    [
      view_title(model.actual),
      view_slider_component(model),
      view_submit_button(model.current_guess),
      view_guesses(model),
    ],
  )
}

fn view_title(actual: Color) {
  html.h1(
    [
      attribute.class(
        text_class_for_background(actual)
        <> " text-4xl font-bold text-center mt-[20%] mg-5",
      ),
    ],
    [
      html.text("Guess this "),
      html.span([attribute.class("rgb text-4xl font-bold")], [html.text("RGB")]),
      html.text("!"),
    ],
  )
}

fn view_navbar() {
  [
    html.a([attribute.href("https://susam.net/myrgb.html")], [
      html.text("Original"),
    ]),
    html.text(", "),
    html.a([attribute.href("https://github.com/george-grec/rgbeam")], [
      html.text("Github"),
    ]),
  ]
}

fn view_slider_component(model: Model) -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "flex flex-col align-center justify-center min-w-full p-10 lg:min-w-[50%]",
      ),
    ],
    [
      view_slider(
        get_color_rgb16(model.current_guess, Red),
        UserChangedColor(_, Red),
        view_basic_color(model.current_guess, Red),
      ),
      view_slider(
        get_color_rgb16(model.current_guess, Green),
        UserChangedColor(_, Green),
        view_basic_color(model.current_guess, Green),
      ),
      view_slider(
        get_color_rgb16(model.current_guess, Blue),
        UserChangedColor(_, Blue),
        view_basic_color(model.current_guess, Blue),
      ),
    ],
  )
}

fn view_slider(
  color_value: Int,
  on_input: fn(String) -> Msg,
  accent_color: String,
) -> Element(Msg) {
  html.input([
    attribute.type_("range"),
    attribute.min("0"),
    attribute.max("15"),
    attribute.width(50),
    attribute.value(int.to_string(color_value)),
    attribute.step("1"),
    attribute.style([#("accent-color", accent_color)]),
    attribute.class("m-2 shrink-0 text-center"),
    event.on_input(on_input),
  ])
}

fn view_basic_color(color: Color, basic_color: BasicColor) -> String {
  let #(r, g, b, a) = colour.to_rgba(color)
  let assert Ok(new_color) = case basic_color {
    Red -> colour.from_rgba(r, 0.0, 0.0, a)
    Green -> colour.from_rgba(0.0, g, 0.0, a)
    Blue -> colour.from_rgba(0.0, 0.0, b, a)
  }

  view_color(new_color)
}

/// returns the color as a string to be displayed to the user
///
/// Example: "#FFF"
fn view_color(color: Color) -> String {
  let red16 = get_color_rgb16(color, Red)
  let green16 = get_color_rgb16(color, Green)
  let blue16 = get_color_rgb16(color, Blue)

  "#" <> int.to_base16(red16) <> int.to_base16(green16) <> int.to_base16(blue16)
}

fn view_submit_button(current_guess: Color) {
  html.button(
    [
      attribute.class(
        "
        text-white text-center m-5 p-5 b-0 block rounded-lg bg-[length:auto_200%] bg-left
        bg-gradient-to-r from-sky-950 to-cyan-600 duration-500 hover:bg-right
        hover:bg-gray hover:no-underline min-w-80",
      ),
      event.on_click(UserGuessed),
    ],
    [element.text("Submit " <> view_color(current_guess))],
  )
}

fn view_guesses(model: Model) {
  html.div(
    [],
    list.zip(model.guesses, list.range(list.length(model.guesses), 1))
      |> list.map(view_guess(_, model.actual)),
  )
}

fn view_slider_label() {
  html.div([], {
    list.range(0, 15)
    |> list.map(int.to_base16)
    |> list.map(fn(x) { html.span([], [html.text(x)]) })
  })
}

fn view_current_percent(current: Color, actual: Color) -> Int {
  let abs_difference = fn(base_color) {
    {
      get_color_float(current, base_color)
      -. get_color_float(actual, base_color)
    }
    |> float.absolute_value
  }

  let abs_red = abs_difference(Red)
  let abs_green = abs_difference(Green)
  let abs_blue = abs_difference(Blue)
  {
    { { 1.0 -. abs_red } /. 1.0 }
    +. { { 1.0 -. abs_green } /. 1.0 }
    +. { { 1.0 -. abs_blue } /. 1.0 }
  }
  /. 3.0
  *. 100.0
  |> float.round
}

fn view_guess(guess_with_count: #(Color, Int), actual: Color) -> Element(Msg) {
  let #(guess, index) = guess_with_count
  let rgb_display = view_color(guess)

  html.div([], [
    html.text(int.to_string(index) <> ") "),
    html.text(rgb_display <> " "),
    html.text(
      "(Accuracy: "
      <> { int.to_string(view_current_percent(guess, actual)) }
      <> "%)",
    ),
    html.div(
      [
        attribute.style([#("background-color", rgb_display)]),
        attribute.width(50),
      ],
      potential_win(guess, actual),
    ),
  ])
}

fn potential_win(guess: Color, actual: Color) -> List(Element(Msg)) {
  case guess == actual {
    False -> []
    True -> [html.text("Perfect match!")]
  }
}

/// get the float value (between 0.0 and 1.0) for either R, G or B
fn get_color_float(color: Color, basic_color: BasicColor) -> Float {
  let #(red, green, blue, _) = colour.to_rgba(color)

  case basic_color {
    Red -> red
    Green -> green
    Blue -> blue
  }
}

/// get the int value (between 0 and 15) for either R, G or B
fn get_color_rgb16(color: Color, basic_color: BasicColor) -> Int {
  float.truncate(get_color_float(color, basic_color) *. 15.0)
}

fn text_class_for_background(color: Color) -> String {
  let assert Ok(dark_text_color) = colour.from_rgb(1.0, 1.0, 1.0)
  case accessibility.contrast_ratio(color, dark_text_color) >. 4.5 {
    True -> "text-white"
    False -> "text-black"
  }
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  UserGuessed
  UserChangedColor(String, BasicColor)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserChangedColor(new_color, color_type) -> #(
      Model(
        ..model,
        current_guess: parse_color(new_color, color_type, model.current_guess),
      ),
      effect.none(),
    )

    UserGuessed -> #(
      Model(..model, guesses: [model.current_guess, ..model.guesses]),
      effect.none(),
    )
  }
}

fn parse_color(
  raw_value: String,
  basic_color: BasicColor,
  fallback current_color: Color,
) -> Color {
  int.parse(raw_value)
  |> result.map(fn(rgb16) {
    let parsed_color_value = int.to_float(rgb16) /. 15.0

    let #(r, g, b, a) = colour.to_rgba(current_color)
    let assert Ok(new_color) = case basic_color {
      Red -> colour.from_rgba(parsed_color_value, g, b, a)
      Green -> colour.from_rgba(r, parsed_color_value, b, a)
      Blue -> colour.from_rgba(r, g, parsed_color_value, a)
    }
    new_color
  })
  |> result.unwrap(current_color)
}

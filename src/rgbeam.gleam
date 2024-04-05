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

const steps = 16

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

// MODEL ----------------------------------------------------------------------
pub type Model {
  Model(actual: Rgb, current_guess: Rgb, guesses: List(Rgb))
}

pub opaque type Rgb {
  Rgb(red: Int, green: Int, blue: Int)
}

fn init(_) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(actual: random_rgb(), guesses: [], current_guess: Rgb(8, 8, 8)),
    effect.none(),
  )
}

fn random_rgb() -> Rgb {
  let random_16 = fn() { random(steps) }
  Rgb(red: random_16(), green: random_16(), blue: random_16())
}

// VIEW -----------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let red = int.to_base16(model.actual.red)
  let green = int.to_base16(model.actual.green)
  let blue = int.to_base16(model.actual.blue)

  let current_red = int.to_base16(model.current_guess.red)
  let current_green = int.to_base16(model.current_guess.green)
  let current_blue = int.to_base16(model.current_guess.blue)

  html.body(
    [
      attribute.style([
        #("background", "#" <> red <> green <> blue),
        #("height", "100vh"),
      ]),
    ],
    [
      ui.centre(
        [],
        ui.stack([], [
          ui.input([
            attribute.type_("range"),
            attribute.min("0"),
            attribute.max("16"),
            attribute.value(int.to_string(model.current_guess.red)),
            attribute.step("1"),
            event.on_input(UserChangedRed),
          ]),
          ui.input([
            attribute.type_("range"),
            attribute.min("0"),
            attribute.max("16"),
            attribute.value(int.to_string(model.current_guess.green)),
            attribute.step("1"),
            event.on_input(UserChangedGreen),
          ]),
          html.input([
            attribute.type_("range"),
            attribute.min("0"),
            attribute.max("16"),
            attribute.value(int.to_string(model.current_guess.blue)),
            attribute.step("1"),
            event.on_input(UserChangedBlue),
          ]),
          ui.button(
            [
              event.on_click(UserGuessed),
              attribute.style([
                #(
                  "background",
                  "#" <> current_red <> current_green <> current_blue,
                ),
              ]),
            ],
            [element.text("Submit")],
          ),
          ui.prose([], [
            html.text(
              "Accuracy: "
              <> {
                int.to_string(
                  float.truncate(view_current_percent(
                    model.current_guess,
                    model.actual,
                  )),
                )
              }
              <> "%",
            ),
          ]),
          ui.stack([], list.map(model.guesses, view_guess)),
        ]),
      ),
    ],
  )
}

fn view_current_percent(current: Rgb, actual: Rgb) {
  let abs_red = int.absolute_value(actual.red - current.red)
  let abs_green = int.absolute_value(actual.green - current.green)
  let abs_blue = int.absolute_value(actual.blue - current.blue)
  {
    { { 16.0 -. int.to_float(abs_red) } /. 16.0 }
    +. { { 16.0 -. int.to_float(abs_green) } /. 16.0 }
    +. { { 16.0 -. int.to_float(abs_blue) } /. 16.0 }
  }
  /. 3.0
  *. 100.0
}

fn view_guess(color: Rgb) -> Element(Msg) {
  let red = int.to_base16(color.red)
  let green = int.to_base16(color.green)
  let blue = int.to_base16(color.blue)

  ui.prose(
    [
      attribute.style([
        #("background-color", "#" <> red <> ", " <> green <> ", " <> blue),
      ]),
    ],
    [
      html.text(
        "#"
        <> int.to_base16(color.red)
        <> int.to_base16(color.green)
        <> int.to_base16(color.blue),
      ),
    ],
  )
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
    UserChangedRed(guessed) -> #(
      Model(
        ..model,
        current_guess: Rgb(
          ..model.current_guess,
          red: result.unwrap(int.parse(guessed), model.current_guess.red),
        ),
      ),
      effect.none(),
    )

    UserChangedGreen(guessed) -> #(
      Model(
        ..model,
        current_guess: Rgb(
          ..model.current_guess,
          green: result.unwrap(int.parse(guessed), model.current_guess.green),
        ),
      ),
      effect.none(),
    )

    UserChangedBlue(guessed) -> #(
      Model(
        ..model,
        current_guess: Rgb(
          ..model.current_guess,
          blue: result.unwrap(int.parse(guessed), model.current_guess.blue),
        ),
      ),
      effect.none(),
    )

    UserGuessed -> #(
      Model(..model, guesses: [model.current_guess, ..model.guesses]),
      effect.none(),
    )
  }

  io.debug(return.0)

  return
}

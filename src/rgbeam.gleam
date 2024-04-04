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
import gleam/bool

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}

// MODEL ----------------------------------------------------------------------
pub type Model {
  Model(actual: Rgb, current_guess: Rgb, guesses: List(Rgb))
}

pub type Rgb {
  Rgb(red: Int, green: Int, blue: Int)
}

fn init(_) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(actual: random_rgb(), guesses: [], current_guess: Rgb(0, 0, 0)),
    effect.none(),
  )
}

fn random_rgb() -> Rgb {
  Rgb(red: random(16) * 16, green: random(16) * 16, blue: random(16) * 16)
}

// VIEW -----------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let red = int.to_string(model.actual.red)
  let green = int.to_string(model.actual.green)
  let blue = int.to_string(model.actual.blue)

  ui.centre(
    [
      attribute.style([
        #(
          "background-color",
          "rgb(" <> red <> ", " <> blue <> ", " <> green <> ")",
        ),
      ]),
    ],
    ui.stack([], [
      html.input([
        attribute.type_("range"),
        attribute.min("0"),
        attribute.max("256"),
        attribute.value(int.to_string(model.current_guess.red)),
        attribute.step("16"),
        event.on_input(UserChangedRed),
      ]),
      html.input([
        attribute.type_("range"),
        attribute.min("0"),
        attribute.max("256"),
        attribute.value(int.to_string(model.current_guess.green)),
        attribute.step("16"),
        event.on_input(UserChangedGreen),
      ]),
      html.input([
        attribute.type_("range"),
        attribute.min("0"),
        attribute.max("256"),
        attribute.value(int.to_string(model.current_guess.blue)),
        attribute.step("16"),
        event.on_input(UserChangedBlue),
      ]),
      ui.button([event.on_click(UserGuessed)], [element.text("Submit")]),
      ui.prose([], [
        html.text(
          "You won: " <> { bool.to_string(model.actual == model.current_guess) },
        ),
      ]),
      ui.stack([], list.map(model.guesses, view_guess)),
    ]),
  )
}

fn view_guess(color: Rgb) -> Element(Msg) {
  let red = int.to_string(color.red)
  let green = int.to_string(color.green)
  let blue = int.to_string(color.blue)

  ui.prose(
    [
      attribute.style([
        #(
          "background-color",
          "rgb(" <> red <> ", " <> blue <> ", " <> green <> ")",
        ),
      ]),
    ],
    [
      html.text(
        "#"
        <> int.to_string(color.red)
        <> int.to_string(color.green)
        <> int.to_string(color.blue),
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

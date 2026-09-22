///|
fn allowed_option(allowed : ArrayView[String], name : String) -> Bool {
  for item in allowed {
    if item == name {
      return true
    }
  }
  false
}

///|
fn parse_options(
  args : ArrayView[String],
  allowed : ArrayView[String],
) -> Result[(Map[String, String], Array[String]), CliError] {
  let options : Map[String, String] = Map([])
  let positional : Array[String] = []
  let mut index = 0
  while index < args.length() {
    let arg = args[index]
    if arg.has_prefix("--") {
      let name = arg.view(start_offset=2).to_owned()
      if !allowed_option(allowed, name) {
        return Err(UnknownOption(arg))
      }
      if index + 1 >= args.length() {
        return Err(MissingArgument(arg))
      }
      options[name] = args[index + 1]
      index += 2
    } else if arg.has_prefix("-") {
      return Err(UnknownOption(arg))
    } else {
      positional.push(arg)
      index += 1
    }
  }
  Ok((options, positional))
}

///|
fn option_or(
  options : Map[String, String],
  name : String,
  default : String,
) -> String {
  match options.get(name) {
    Some(value) => value
    None => default
  }
}

///|
fn require_positional_count(
  positional : Array[String],
  expected : Int,
  description : String,
) -> Result[Unit, CliError] {
  if positional.length() < expected {
    Err(MissingArgument(description))
  } else if positional.length() > expected {
    Err(InvalidValue(description, positional[expected]))
  } else {
    Ok(())
  }
}

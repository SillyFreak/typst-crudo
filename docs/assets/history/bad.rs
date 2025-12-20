pub fn main() {
    // @region start:simple
    println!("Hello World");
    // @region end:simple start:parametric
    let name = todo!();
    println!("Hello {name}");
    // @region end:parametric start:localized
    let local_greeting = todo!();
    let name = todo!();
    println!("{local_greeting} {name}");
    // @region end:localized
}
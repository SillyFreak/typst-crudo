// @start:simple
pub fn main() {
    /* @before:parametric
    println!("Hello World");
    */
    // @start:localized
    let local_greeting = todo!();
    // @end:localized
    // @start:parametric
    let name = todo!();
    /* @before:localized
    println!("Hello {name}");
    */
    // @end:parametric
    // @start:localized
    println!("{local_greeting} {name}");
    // @end:localized
}
// @end:simple

import QtQuick
import QtTest
import "../Calc.js" as Calc

TestCase {
    name: "Calc"

    function test_arithmetic() {
        compare(Calc.evaluate("2+3*4"), 14)
        compare(Calc.evaluate("(2+3)*4"), 20)
        compare(Calc.evaluate("2^3^2"), 512)   // right-associative
        compare(Calc.evaluate("-2^2"), -4)
        compare(Calc.evaluate("10 % 4"), 2)
        compare(Calc.evaluate("7/2"), 3.5)
        compare(Calc.evaluate("1.5e3 + 1"), 1501)
    }

    function test_functions_and_constants() {
        compare(Calc.evaluate("sqrt(16) + abs(-2)"), 6)
        fuzzyCompare(Calc.evaluate("2*pi"), 6.283185307, 1e-6)
        fuzzyCompare(Calc.evaluate("ln(e)"), 1, 1e-12)
        compare(Calc.evaluate("log(1000)"), 3)
    }

    function test_not_math_gives_null() {
        compare(Calc.evaluate("firefox"), null)
        compare(Calc.evaluate("42"), null)         // a bare number isn't a calculation
        compare(Calc.evaluate("2+"), null)
        compare(Calc.evaluate("alert(1)"), null)   // unknown function
        compare(Calc.evaluate("(1+2"), null)
        compare(Calc.evaluate(""), null)
    }

    function test_format() {
        compare(Calc.format(3.5), "3.5")
        compare(Calc.format(1 / 3), "0.3333333333")
        compare(Calc.format(1e21), "1e+21")
        compare(Calc.format(0.1 + 0.2), "0.3")
    }
}

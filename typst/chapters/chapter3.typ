#import "../thm/abbreviations.typ": *

= Einbinden von Grafiken, Sourcecode und Anforderungen

== Bilder

Natürlich können auch Grafiken und Bilder eingebunden werden, siehe #zb @NasaRover. Hierbei ist zu beachten, dass Typst die Bilder automatisch positioniert, sie also nicht zwingend an der Stelle erscheinen, an der sie im Quelltext vorkommen. Das ist vollkommen in Ordnung und im Sinne einer ausgeglichenen Typografie auch sinnvoll.

#figure(
  image("../images/nasa_rover.jpg", width: 6cm),
  caption: [Ein Nasa Rover]
) <NasaRover>

== Formelsatz

$ a^2 + b^2 = c^2 $

$
sum_(k=1)^n k = (n(n+1)) / 2
$

$
integral_0^oo (f(t) + g(t))/2
$


== Sourcecode

Sourcecode kann über \`\`\` eingebunden werden, siehe @SourceBeispiel.

#figure(
```java
/**
 * Testet den Schlüssel auf Korrektheit: Er muss mindestens die Länge 1
 * haben und darf nur Zeichen von A-Z enthalten.
 *
 * @param key zu testender Schlüssel
 * @throws CrypterException wenn der Schlüssel nicht OK ist.
 */
protected void checkKey(Key key) throws CrypterException {

    // Passt die Länge?
    if (key.getKey().length == 0) {
        throw new CrypterException("Der Schlüssel muss mindestens " +
                "ein Zeichen lang sein");
    }

    checkCharacters(key.getKey(), ALPHABET);
}
```
) <SourceBeispiel>

Mitten im Text kann man Source mit \` einschließen: `checkKey`-Methode.

== Anforderungen

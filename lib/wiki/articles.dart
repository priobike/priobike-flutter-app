import 'models/article.dart';

/// Article about data failures.
const Article articleDataFailures = Article(
  "Datenausfälle",
  "Wenn die Ampeln schweigen",
  "3 min.",
  "assets/images/wiki/wiki-datenausfaelle-icon.png",
  [
    "Wir bei PrioBike möchten sicherstellen, dass Du immer sicher und schnell durch die Stadt radeln kannst. Deshalb arbeiten wir unter Hochdruck daran, unsere Geschwindigkeitsempfehlungen so zuverlässig wie möglich zu machen. Das klappt aber nicht immer.",
    "Unsere Geschwindigkeitsempfehungen basieren auf den Echtzeitdaten, die uns Ampeln in Hamburg senden. Anhand der Echtzeitdaten können wir dann die Schaltprogramme der Ampeln rekonstruieren, und daraus die Geschwindigkeitsempfehlung berechnen. Manchmal kommt es aber vor, dass die Daten der Ampeln ausfallen oder nicht ganz zuverlässig sind.",
    "Hinter dem System versteckt sich ein kompliziertes Netzwerk aus Ampeln und Verkehrsrechnern, in dem Ausfälle nicht ausgeschlossen sind. Im besten Fall erhalten wir über 10.000 Nachrichten der Ampeln in Hamburg jede Minute - eine riesige Menge Daten! Die müssen auch erstmal durch die Internetleitung passen. Wir tun alles dafür, dass Ausfälle in Zukunft so selten sind wie möglich.",
    "Wenn es dann doch mal nicht so gut klappt, kannst Du das aber schon im Voraus über die Verfügbarkeit von Ampeln entlang deiner Route in der App sehen. Damit weißt Du immer voll Bescheid.",
  ],
  [
    "assets/images/wiki/wiki-datenausfaelle-1.png",
    "assets/images/wiki/wiki-datenausfaelle-2.png",
    "assets/images/wiki/wiki-datenausfaelle-3.png",
    "assets/images/wiki/wiki-datenausfaelle-4-v2.png",
  ],
);

/// Article about switching programs.
const Article articleSwitchingPrograms = Article(
  "Der Tanz mit Ampeln",
  "Statische und Dynamische Schaltprogramme",
  "4 min.",
  "assets/images/wiki/wiki-tanz-mit-den-ampeln-icon.png",
  [
    "Hast Du schon mal versucht, eine Ampel zu überlisten, indem Du deine Geschwindigkeit anpasst, um nicht bei rot stehen bleiben zu müssen? Ich meine, wer hat das nicht schon mal gemacht, oder? Aber wusstest Du, dass es einen großen Unterschied zwischen statischen und dynamischen Ampelprogrammen gibt und dass das Deine Fähigkeit, eine Ampel zu überlisten, beeinflussen kann?",
    "Bei statischen Ampelprogrammen weißt Du genau, wann das Grünlicht kommt und wie lange es dauert. Das bedeutet, dass Du mit der PrioBike-App genau berechnen kannst, wie schnell Du fahren musst, um die Ampel bei Grün zu erreichen. Es ist wie ein perfekter Tanz, bei dem Du genau weißt, wann Du die Schritte machen musst.",
    "Aber bei dynamischen Ampelprogrammen ist das Ganze viel schwieriger. Denn hier weißt Du nicht immer genau, wann das Grünlicht kommt. Manchmal ändert sich die Dauer der Grünphase aufgrund von Bussen oder anderen Verkehrsteilnehmern, die die Ampel anfordern. Es ist wie eine unvorhersehbare Tanzparty, bei der Du nie weißt, wann das Lied endet oder wer als nächstes tanzen wird.",
    "Und das macht es schwieriger für die PrioBike-App, Dir genaue Geschwindigkeitsempfehlungen zu geben. Auch wenn es dem allgemeinen Verkehrsfluss hilft - je dynamischer die Ampelschaltung ist, desto unsicherer wird die Vorhersage. Das bedeutet, dass die Farbe im Tacho dunkler wird, je unsicherer sich die App ist, dass Du die Ampel bei Grün passierst.",
    "Aber lass Dich nicht entmutigen, denn das bedeutet nicht, dass Du die App nicht mehr nutzen sollst. Nach dieser Ampel kommt die nächste, die dann wieder besser funktioniert. In der Zwischenzeit arbeiten wir natürlich aktiv daran, auch für dynamische Ampelprogramme bessere Empfehlungen zu geben!",
  ],
  [
    "assets/images/wiki/wiki-tanz-mit-den-ampeln-1.png",
    "assets/images/wiki/wiki-tanz-mit-den-ampeln-2.png",
    "assets/images/wiki/wiki-tanz-mit-den-ampeln-3.png",
    "assets/images/wiki/wiki-tanz-mit-den-ampeln-4.png",
    "assets/images/wiki/wiki-tanz-mit-den-ampeln-5.png",
  ],
);

/// Article about the SG selector.
const Article articleSGSelector = Article(
  "Die Ampel-Fee",
  "Wie unsere App die richtigen Ampeln für Dich auswählt",
  "2 min.",
  "assets/images/wiki/wiki-sg-selektor-icon.png",
  [
    "Wisst ihr eigentlich, wie wir bei unserer Fahrrad-App die Ampeln entlang eurer Route auswählen? Keine Sorge, wir ziehen die natürlich nicht zufällig aus einer Urne, sondern setzen auf moderne Technologien.",
    "Hier kommt unser spezielles Machine-Learning-Verfahren zum Einsatz, welches automatisch die passenden Ampeln auswählt. Dabei nutzen wir immer die Fahrradampeln, um euch die bestmöglichen Empfehlungen zu geben. Den Rest erledigt künstliche Intelligenz für uns.",
    "Aber Vorsicht: Solltet ihr mal auf der Straße statt dem Fahrradweg fahren, kann es sein, dass ihr Empfehlungen für die daneben stehende Fahrradampel bekommt. Kein Grund zur Panik, das ist kein Fehler - wir wollen schließlich sicherstellen, dass ihr immer auf dem richtigen Weg seid.",
    "Und ja, manchmal kann es passieren, dass eine falsche Ampel ausgewählt wird. Aber keine Sorge, wir tun unser Bestes, um solche Fehler möglichst gering zu halten.",
  ],
  [
    "assets/images/wiki/wiki-sg-selektor-1.png",
    "assets/images/wiki/wiki-sg-selektor-2.png",
    "assets/images/wiki/wiki-sg-selektor-3.png",
    "assets/images/wiki/wiki-sg-selektor-4.png",
  ],
);

/// Article about PrioBike
const Article articlePrioBike = Article(
  "Das Projekt",
  "Wenn Radfahren zur Wissenschaft wird",
  "3 min.",
  "assets/images/wiki/wiki-das-projekt-icon.png",
  [
    "Hallo liebe Radfahrerinnen und Radfahrer! Ich bin PrioBike, eure freundliche Fahrrad-App. Aber ich bin nicht nur eine App, sondern Teil eines großen Projekts, das Hamburg zu einer fahrradfreundlicheren Stadt machen will.",
    "Unser neuestes Ding sind die \"Grünen Welle\" entlang von Velorouten. Wenn ihr diese Routen benutzt, werdet ihr nicht nur mit frischer Luft und einer schönen Aussicht belohnt, sondern auch mit einer statischen Grünen Welle, die euch mit 18 km/h bei Grün durchfahren lässt. Wenn das kein Grund ist, sich aufs Rad zu schwingen...",
    "Aber das ist noch lange nicht alles. Habt ihr schon die PrioBike-Säule auf der Rothenbaumchaussee entdeckt? Sie ist einzigartig in Deutschland und berechnet für jeden Radfahrenden eine individuelle Geschwindigkeitsempfehlung.",
    "Und als ob das noch nicht genug wäre, gibt es an einer Kreuzung sogar eine Umkehrung der klassischen Ampel-Priorisierung. Hier wird der Fuß- und Radverkehr bevorzugt, während der Kfz-Verkehr grünes Licht nur bei Bedarf erhält.",
    "Und wenn ihr denkt, das war schon alles, täuscht ihr euch. Wir haben noch viele weitere Radinfrastrukturverbesserungen in petto, wie die Erweiterung der Velorouten und vieles mehr. In Zukunft werden wir euch noch mehr coole Dinge bieten, damit ihr eure Radtouren in vollen Zügen genießen könnt.",
    "Also schnappt euch euer Fahrrad und macht euch auf den Weg.",
  ],
  [
    "assets/images/wiki/wiki-das-projekt-1.png",
    "assets/images/wiki/wiki-das-projekt-2.png",
    "assets/images/wiki/wiki-das-projekt-3.png",
    "assets/images/wiki/wiki-das-projekt-4.png",
    "assets/images/wiki/wiki-das-projekt-5.png",
    "assets/images/wiki/wiki-das-projekt-6.png",
  ],
);

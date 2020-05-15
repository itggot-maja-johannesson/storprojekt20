# Projektplan

## 1. Projektbeskrivning (Beskriv vad sidan ska kunna göra)
Min webbapplikation ska fungera liknande som "Blocket" gör, men med skillnaden att den inte kommer vara lika utvecklad med alla funktioner. Det man ska kunna göra på sidan är att skapa konto, logga in, lägga upp inlägg (om man har ett konto), ta bort och redigera sina egna inlägg, och kommentera på alla inlägg (om man är inloggad) och ta bort sina egna kommentarer. På inläggen ska man kunna skriva titel, beskrivning, lägga till bild, flera kategorier och pris.  

## 2. Vyer (visa bildskisser på dina sidor)
Finns ej skisser.

## 3. Databas med ER-diagram (Bild)
![](https://github.com/itggot-maja-johannesson/storprojekt20/blob/master/Dokumentation/NYTT_ER.JPG?raw=true)

## 4. Arkitektur (Beskriv filer och mappar - vad gör/inehåller de?)
I min public mapp ligger css och en mapp med alla bilder som laddas upp när man publicerar ett inlägg. I views mappen ligger tre mappar som heter "comments", "posts" och "users". I alla dessa mappar ligger slimfiler efter vyerna på webbapplikationen. I views mappen ligger även filerna "index.slim" och "layout.slim". I root mappen ligger två ruby-filer som heter "app.rb" och "model.rb". I App.rb ligger alla routes och är alltså controllern. I Model.rb finns det funktioner som hanterar information till/från databasen, och även andra funktioner som är bara är ruby-kod. 

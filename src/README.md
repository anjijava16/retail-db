Baza danych dla sieci sklepów
=============================

I. Relacje
----------
Baza danych w obecnym schemacie odzwierciedla następujące obiekty
świata rzeczywistego:

* Oddziały firmy
* Pracownicy
* Klienci
* Produkty i ich kategorie
* Zamówienia i ich dostawy
* Kupony

Poniżej znajduje się bardziej szczegółowy opis implementacji każdego
z elementów powyższej listy.

### Oddziały firmy

#### BRANCH

| Pole      | Atrybuty |
|-----------|----------|
| branch_id | PK       |
| address   | NOT NULL |
| city      |          |

W relacji `BRANCH` znajdują się jedynie id i adres danego oddziału,

#### BRANCH_PHONE

| Pole      | Atrybuty   |
|-----------|------------|
| branch_id | FK(BRANCH) |
| phone     | PK         |
| fax       | NOT NULL   |

W osobnej relacji `BRANCH_PHONE` znajdują się dane telekontaktowe do oddziałów.
Składa się ona z klucza obcego wskazującego na `BRANCH`, numeru telefonu oraz
boolowskiej wartości mówiącej czy dany numer jest faxem. Jeśli klucz obcy ma
wartość NULL, oznacza to że dany numer jest numerem międzyoddziałowej infolinii
(0-800) i może posłużyć on do kontaktu z dowolnym oddziałem.

### Pracownicy

#### POSITION

| Pole           | Atrybuty     |
|----------------|--------------|
| position_id    | PK           |
| name           | NOT NULL     |
| base_wage      | NOT NULL     |
| salesman       | NOT NULL     |

W relacji `POSITION` znajdują się dane o stanowiskach istniejących we wszystkich
oddziałach firmy - m.in. podstawowa stawka godzinowa, nazwa stanowiska i wartość
boolowska mówiąca czy pracownicy na danym stanowisku mogą być przydzielani do
obsługi zamówień i kontaktu z klientem.

#### EMPLOYEE

| Pole           | Atrybuty            |
|----------------|---------------------|
| employee_id    | PK                  |
| first_name     | NOT NULL            |
| last_name      | NOT NULL            |

Relacja `EMPLOYEE` zawiera jedynie podstawowe informacje o pracowniku.

#### EMPLOYEE_POSITION

| Pole           | Atrybuty            |
|----------------|---------------------|
| employee_id    | PK                  |
| position_id    | FK(POSITION)        |
| superior_id    | FK(EMPLOYEE)        |
| branch_id      | FK(BRANCH)          |
| extra_wage     |                     |
| hours_per_week | NOT NULL            |
| since          | PK NOT NULL         |

Relacja kojarząca pracowników z ich aktualną pozycją i warunkami zatrudnienia.
Pozwala to kadrom na przechowywanie historii zatrudnienia każdego pracownika.
Znajduje się tutaj aktualna pozycja, id przełożonego, id oddziału, w którym
zatrudniony jest pracownik, premia, tygodniowy wymiar czasu pracy, oraz
datę od kiedy obowiązują te informacje.

### Klienci

#### CLIENT_ADDRESS

| Pole              | Atrybuty   |
|-------------------|------------|
| client_address_id | PK         |
| client_id         | FK(CLIENT) |
| first_name        | NOT NULL   |
| last_name         | NOT NULL   |
| company           |            |
| address           | NOT NULL   |
| city              | NOT NULL   |
| email             | NOT NULL   |
| phone             |            |
| fax               |            |

W relacji `CLIENT_ADDRESS` znajdują się dane adresowe związane z klientem. Znalazły
się one w osobnej tabeli, ponieważ jeden klient może mieć takie same lub różne 
domyślne dane do wysyłki i do wystawienia faktury. W pierwszym przypadku pozbywamy się
repetycji tych samych danych w bazie. Ponadto pozwala to na szybkie wypełnienie
formularza zamówienia w przypadku częstego wysyłania zamówień w te same różne miejsca.

#### CLIENT

| Pole                        | Atrybuty           |
|-----------------------------|--------------------|
| client_id                   | PK                 |
| default_shipment_address_id | FK(CLIENT_ADDRESS) |
| default_billing_address_id  | NOT NULL           |

Relacja `CLIENT` zawiera jedynie id klienta i dwa klucze obce do tabeli `CLIENT_ADDRESS` - 
jeden dla domyślnego adresu wysyłki, drugi dla domyślnych danych potrzebnych do
wystawienia faktury.

### Produkty i ich kategorie

#### CATEGORY

| Pole        | Atrybuty     |
|-------------|--------------|
| category_id | PK           |
| parent_id   | FK(CATEGORY) |
| name        | NOT NULL     |
| vat         | NOT NULL     |

Relacja `CATEGORY` opisuje drzewistą strukturę kategorii produktów. Zawiera id, pole z nazwą
kategorii oraz klucz obcy do ojca danej kategorii (NULL dla korzenia).


#### PRODUCT

| Pole        | Atrybuty     |
|-------------|--------------|
| product_id  | PK           |
| category_id | FK(CATEGORY) |
| name        | NOT NULL     |
| weight      |              |

W relacji `PRODUCT` znajduje się id produktu, klucz obcy do kategorii, nazwa, oraz waga produktu
(potrzebna do szacowania kosztów wysyłki). Cena produktu znajduje się w relacji `PRODUCT_PRICE`.
Zawiera ona cenę oraz datę wskazującą na pierwszy dzień obowiązywania danej ceny. Ponadto
w relacji `PRODUCT_STOCK` przechowywana jest informacja nt. dostępności danego produktu w
danym oddziale (zawiera ona klucz podstawowy złożony z klucza obcego do `BRANCH` i klucza obcego
do `PRODUCT`).

### Zamówienia i dostawy

#### ORDER

| Pole                | Atrybuty           |
|---------------------|--------------------|
| order_id            | PK                 |
| client_id           | FK(CLIENT)         |
| billing_address_id  | FK(CLIENT_ADDRESS) |
| shipping_address_id | FK(CLIENT_ADDRESS) |
| created_at          | NOT NULL           |
| salesman_id         | FK(EMPLOYEE)       |
| paid                | NOT NULL           |
| shipment_type_id    | FK(SHIPMENT_TYPE)  |
| shipped_at          | NOT NULL           |
| tracking            |                    |

Zamówienia przechowywane są w relacji `ORDER`, która zawiera odpowiednie
klucze obce i pola jak informacje o kliencie, dane do faktury, id
pracownika odpowiedzialnego za realizację zamówienia (`salesman_id`). 
W przypadku gdy klient wybrał pokwitowanie w formie paragonu, dane do
faktury są nullem. Pole `shipped_at` zawiera null lub datę wysłania
przesyłki, jesli to nastąpiło. Pole `paid` zawiera true, jesli opłacono zamówienie.
W polu `tracking` znajduje się numer przewozowy przesyłki, jeśli
takowy istnieje.

#### SHIPMENT_TYPE

| Pole                | Atrybuty     |
|---------------------|--------------|
| shipment_type_id    | PK           |
| name                | NOT NULL     |
| min_order_value     | NOT NULL     |
| max_weight          |              |
| cost                | NOT NULL     |
| payment_on_delivery | NOT NULL     |

Relacja ta przechowuje informacje o dostępnych opcjach wysyłki. Opcje wysyłki mogą być dostępne
dla zamówień w pewnej kategorii wagowej lub od pewnej wartości zamówienia. Pole `PAYMENT_ON_DELIVERY`
przechowuje boolowską wartość oznaczającą wysyłkę za pobraniem.

#### ORDER_PRODUCT

| Pole        | Atrybuty        |
|-------------|-----------------|
| order_id    | PK, FK(ORDER)   |
| product_id  | PK, FK(PRODUCT) |
| quantity    | NOT NULL        |

Relacja kojarząca zamówienia z produktami.

### Kupony

#### COUPON

| Pole        | Atrybuty     |
|-------------|--------------|
| coupon_id   | PK           |
| client_id   | FK(CLIENT)   |
| category_id | FK(CATEGORY) |
| product_id  | FK(PRODUCT)  |
| valid_from  | NOT NULL     |
| valid_to    | NOT NULL     |
| claim_limit |              |
| discount    |              |

Wszystkie kupony przechowywane są w relacji `COUPON`. Wyróżniamy kupony:

* na całe zamówienie (`CATEGORY_ID` i `PRODUCT_ID` są nullami)
* na produkty jednej kategorii
* na jeden produkt

Ponadto każdy taki kupon może ograniczony do jednego klienta. Pole
`DISCOUNT` zawiera wartość zniżki jako liczba z przedziału `(0,1]`.

#### ORDER_COUPON

| Pole        | Atrybuty       |
|-------------|----------------|
| coupon_id   | PK, FK(COUPON) |
| order_id    | PK, FK(CLIENT) |

Relacja kojarząca zamówienia z kuponami.

II. Integralność danych
-----------------------

Baza danych jest zaopatrzona w wiele constraintów i triggerów zapewniających
integralność danych. Dbamy między innymi o:

* acykliczność drzewa kategorii
* poprawne przydzielanie kuponów do zamówień (wymagany klient i/lub produkty)
* podstawowa integralność bazy zamówień tj.
	* automatyczne przydzielenie najbardziej ekonomicznego oddziału i pracownika do obsługi zamówienia
	* automatyczna aktualizacja informacji o dostępności produktu po złożeniu zamówienia (zmniejszenie ilości dostępnych produktów)
	* niepustość listy produktów w zamówieniu
	* walidacja wybranego sposobu wysyłki (wymagana minimalna wartość zamówienia/maksymalna waga)
* podstawowa integralność bazy produktów tj.
	* upewnienie się że istnieje co najmniej jedna cena w historii cen dla każdego produktu
	* zabronienie modyfikacji istniejących cen jeśli naruszałoby to integralność danych (tj. istnieje zamówienie złożone w czasie gdy obowiązuje cena z krotki ulegającej zmianie i może to spowodować zmianę wartości zamówienia)


III. Widoki i funkcje
---------------------

Baza posiada zaimplementowane funkcje i widoki ułatwiające pracę z danymi.

Funkcje:

* `category_ancestors(INTEGER)`, `category_descendants(INTEGER)` - zwracają przodków i potomków danej kategorii w drzewie
* `order_products(INTEGER)` - zwraca listę wszystkich produktów związanych z zamówieniem razem z cenami obowiązującymi w dniu złożenia zamówienia i zniżkami
* `order_information(INTEGER)` - jak wyżej wraz z doliczoną wysyłką (jeśli dotyczy)
* `find_best_salesman(INTEGER)` - znajduje najlepszego sprzedawcę do obsługi danego zamówienia (dot. zamówień przez internet). bierze pod uwagę zajętość pracowników oraz stan zamówionych produktów w poszczególnych oddziałach.

Widoki:

* `product_price_detail` - widok zawierający te same informacje co tabela `product_price` rozszerzone o kolumnę `ends_at` z datą oznaczającą kiedy dana cena przestała obowiązywać
* `employee_detail` - zawiera informacje o obecnym stanie zatrudnienia wszystkich pracowników (z tabeli dot. historii zatrudnienia wybierane są aktualne dane)
* `remote_order` - widok filtrujący zamówienia złożone przez internet. zawiera informacje o wysyłce oraz adres.
* `local_order` - widok filtrujący zamówienia zrealizowane osobiście w sklepie. zawiera informacje o oddziale.
* `pending_order` - widok filtrujący zamówienia internetowe, które nie zostały jeszcze wysłane.
* `salesman_achievements` - widok zawierające informacje o utargu osiągniętym przez każdego z pracowników w ciagu ostatnich 7 dni/30 dni/roku. 
* `category_detail` - widok zawierający ścieżkę od korzenia do danej kategorii w drzewie
* `branch_detail` - widok pozwalający na podliczenie utargu w każdym oddziale w ciągu ostatnich 7 dni/30 dni/roku. 

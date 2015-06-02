|
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
| last_name                   | NOT NULL           |

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
| created_at          | NOT NULL           |
| salesman_id         | FK(EMPLOYEE)       |
| paid                | NOT NULL           |

Zamówienia przechowywane są w relacji `ORDER`, która zawiera odpowiednie klucze obce i pola jak
informacje o kliencie, dane do faktury, pracownik odpowiedzialny za realizację
zamówienia. W przypadku gdy klient wybrał pokwitowanie w formie paragonu, dane do faktury są
nullem. Gdy zamówienie nie było dokonane przez internet, lecz było jednorazowym zakupem w lokalnym
sklepie przez anonimowego klienta, wówczas informacje o kliencie są nullowane.

#### SHIPMENT_TYPE

| Pole                | Atrybuty     |
|---------------------|--------------|
| shipment_type_id    | PK           |
| name                | NOT NULL     |
| min_order_value     | NOT NULL     |
| max_weight          |              |
| cost                | NOT NULL     |
| payment_on_delivery | FK(EMPLOYEE) |

Relacja ta przechowuje informacje o dostępnych opcjach wysyłki. Opcje wysyłki mogą być dostępne
dla zamówień w pewnej kategorii wagowej lub od pewnej wartości zamówienia. Pole `PAYMENT_ON_DELIVERY`
przechowuje boolowską wartość oznaczającą wysyłkę za pobraniem.

#### ORDER_SHIPMENT

| Pole                | Atrybuty           |
|---------------------|--------------------|
| order_id            | PK, FK(ORDER)      |
| shipment_type_id    | FK(SHIPMENT_TYPE)  |
| shipping_address_id | FK(CLIENT_ADDRESS) |
| shipped             | NOT NULL           |
| tracking            |                    |

Relacja kojarząca zamówienia z wysyłkami. Wyodrębniona z `ORDER` dla oszczędności pamięci ponieważ
duża ilość zamówień będzie realizowana w lokalnych sklepach bez wysyłki. Zawiera klucze obce do
zamówienia, typu wysyłki i adresu. `SHIPPED` przyjmuje wartość true po wysłaniu wysyłki. Jeśli
istnieje numer trackingowy, to zostaje on umieszczony w polu `TRACKING`.


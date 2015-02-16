<!DOCTYPE html>
    <head>
        <title>Stormrider</title>
        <meta charset="utf-8">
        <link rel="stylesheet" type="text/css" href="main.css">
        <link href='http://fonts.googleapis.com/css?family=Prociono' rel='stylesheet' type='text/css'>
        <script src="http://code.jquery.com/jquery-latest.min.js"></script>
        <script type="text/javascript">
          // Makes sure items are listed from the beginning
          $(document).ready(fetchItems());

            var beer_ids = [];
            var labels = [];
            var prices = [];
            var counts = [];

          // Checks the search field and sorts out beers matching the description
          // Empty search field implies all beers are listed
          function fetchItems(){
            var counter;
            var index;
            $.getJSON(
              'http://pub.jamaica-inn.net/fpdb/api.php?' +
              'username=<?php echo $_SESSION['username'];?>' +
              '&password=<?php echo $_SESSION['password'];?>' + // MAJOR security flaw
              '&action=inventory_get',
              function(data) {
              $("div#drink_table").empty();
              var search_string = $("#search").val().toLowerCase();
              var search_array = search_string.split(" ");
              var lower_bound = Math.ceil((search_array.length)/2);
              $("div#drink_table").append('<table id="drink_table"></table>');
              $.each(data.payload, function (key, beer){
                var namn = beer.namn.toLowerCase();
                var tot_namn = namn + ' ' + beer.namn2.toLowerCase();

                // Checks how many of the search term has a match on the label
                counter = 0;
                for (index = 0; index < search_array.length; index++) {
                  if (search_array[index].length > 0 &&
                      tot_namn.indexOf(search_array[index]) > -1) {
                    counter++;
                  }
                }
                // Filters out items where name is not empty and where enough
                // search terms exist in the item
                if(namn.length > 0 &&
                  (search_string.length == 0 || counter >= lower_bound)){
                  var beer_namn_string =
                    beer.namn2.length == 0 ?
                      beer.namn :
                      beer.namn + '<br>(' + beer.namn2 + ')';

                  // Updates the arrays containing the information
                  var beer_index = beer_ids.indexOf(beer.beer_id);
                  if (beer_index > -1) {
                    labels[beer_index] = beer_namn_string;
                    prices[beer_index] = beer.pub_price;
                    counts[beer_index] = beer.count;
                  } else {
                    beer_ids.push(Number(beer.beer_id));
                    labels.push(tot_namn);
                    prices.push(beer.pub_price);
                    counts.push(beer.count);
                  }

                  // Updates the table with search results
                  $("table#drink_table").append(
                    '<tr>' +
                      '<td><button ' +
                              'class="item"' +
                              'onclick="addToCart(' + beer.beer_id + ')" ' +
                              'draggable="true">' +
                              beer_namn_string +
                            '</button></td>' +
                      '<td>' + beer.pub_price + '</td>' +
                      '<td>' + beer.count + '</td>' +
                    '</tr>');
                }
              });
              }
          );
          }

          function getLabel(beer_id) {
            var index = beer_ids.indexOf(beer_id);
            return labels[index];
          }

          function getPrice(beer_id) {
            var beer_index = beer_ids.indexOf(beer_id);
            return prices[beer_index];
          }

          function addToCart(beer_id) {
            //Create the row containing the name of the beer and price
            var row = document.createElement("TR");
            var labelCell = document.createElement("TD");
            var label = getLabel(beer_id);
            var labelNode = document.createTextNode(label);
            var numberCell = document.createElement("TD");
            var priceCell = document.createElement("TD");
            var price = Number(getPrice(beer_id));
            var priceNode = document.createTextNode(price);
            row.appendChild(labelCell);
            row.appendChild(priceCell);
            labelCell.appendChild(labelNode);
            priceCell.appendChild(priceNode);

            // Append the row
            document.getElementById("shopping_cart").appendChild(row);

            // Add the price to the sessions total
            var priceNode = document.createElement("TD");
            if (sessionStorage.subtotal) {
              sessionStorage.subtotal = Number(sessionStorage.subtotal) + price;
            } else {
              sessionStorage.subtotal = price;
            }
            document.getElementById("subtotal").innerHTML = sessionStorage.subtotal;
          }
        </script>
    </head>
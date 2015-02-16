<?php 
  include_once 'check.php';
  include_once 'header.php';
?>
  <body>
      <div class="wrapper header">
        <div class="title"></div>
        <div class="title"></div>
        <div class="title"></div>
        <div class="title"></div>
      </div>
      <div class="wrapper">
        <div class="title">
          <h2>Search available beers</h2>
          <input autocomplete="off" id="search" placeholder="Search ..." type="text" onkeydown="fetchItems()"></input>
        </div>
        <div class="title"><h2>Most bought</h2></div>
        <div class="title"><h2>Shopping cart</h2></div>
      </div>  
      <div class="wrapper">
        <div class="row" id="drink_table"></div>
        <div class="row" id="most_bought"></div>
        <div class="row" id="cart_div"><table id="shopping_cart"><td>Total:</td><td id="subtotal"></td></table></div>
    </div>
  </body>
</html>
<?php exit?>
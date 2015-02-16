function fetch_items(){
	$.getJSON(
    'http://pub.jamaica-inn.net/fpdb/api.php?username=anddar&password=anddar&action=inventory_get', 
    function(data) { 
		$("div").empty();
		var searchString = $("#beerName").val();
		$("div").append("<ul></ul>");
		$.each(data.payload, function (key, beer){
			if(beer.namn && beer.namn.length > 0 && (!searchString || searchString.length == 0 || beer.namn.toLowerCase().indexOf(searchString.toLowerCase()) >= 0)){
				$("ul").append("<li>" + beer.namn + "</li>");
			}
		});		
    }
);
}

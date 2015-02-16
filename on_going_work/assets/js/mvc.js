/*
 * Event handler
 * @class Event
 * @constructor
 */
function Event(sender) {
    this._sender = sender;
    this._listeners = [];
}

Event.prototype = {
    attach: function (listener) {
        this._listeners.push(listener);
    },
    notify: function (args) {
        var index;

        for (index = 0; index < this._listeners.length; index += 1) {
            this._listeners[index](this._sender, args);
        }
    }
};

/*
 * An item in a pub. 
 * @class Item
 * @param {String} name
 * @param {String} name2
 * @param {Float} sbl_price
 * @param {Float} pub_price
 * @param {Integer} id
 * @param {Integer} count
 * @param {Float} price
 * @constructor
 * Creates an Item
 */
function Item(name, name2, sbl_price, pub_price, id, count, price) {
    this._name = name;
    this._name2 = name2;
    this._sbl_price = sbl_price;
    this._pub_price = pub_price;
    this._id = id;
    this._count = count;
    this._price = price;
}

Item.prototype = {
    getName: function () {
	return this._name;
    },
    getName2: function () {
	return this._name2;
    },

    getFullName: function () {
	return ((this._name2.length == 0) ? this._name :
		this._name + '<br>(' + this._name2 + ')');
    },

    getSblPrice: function () {
	return this._sbl_price;
    },

    getPubPrice: function () {
	return this._pub_price;
    },

    getId: function () {
	return this._id;
    },

    getCount: function () {
	return this._count;
    },

    getPrice: function () {
	return this._price;
    }
};

/*
 * The Model. Model stores items and notifies observers about changes.
 * @class DataBaseModel
 * @parent index
 * @constructor
 * Creates a database model
 */
function DatabaseModel() {
    this._itemList = [];
    this._temp = [];
    this._db_inventory = 'http://pub.jamaica-inn.net/fpdb/api.php?username=anddar&password=anddar&action=inventory_get';

    this.listUpdated = new Event(this); 
}

DatabaseModel.prototype = {
    /*
     * Drops the database.
     * @function _drop
     */
    _drop: function () {
	while(this._itemList.length > 0) {
	    this._itemList.pop();
	}
    },    
    
    /*
     * Checks how many of the search term has a match on the label
     * @function _getCount
     * @return {Integer} 
     */
    _getCount: function(name, searchArray) {
	var count = 0;
        for (var index = 0; index < searchArray.length; index++) {
            if (searchArray[index].length > 0 &&
                name.indexOf(searchArray[index]) > -1) {
                count++;
            }
        }
	return count;
    },

    /*
     * Filters out items where name is not empty and where enough search terms exist in the item
     * @function _filter
     * @return {Item} 
     */
    _filter: function(query, item, _this) {
	var searchString = query.toLowerCase();
        var searchArray = searchString.split(" ");
        var lowerBound = Math.ceil((searchArray.length)/2);
	var name = item.namn.toLowerCase();
	var nameAndName2 = name + ' ' + item.namn2.toLowerCase();
	var count = _this._getCount(nameAndName2, searchArray);
	
	if (name.length > 0 && (searchString.length == 0 || count >= lowerBound)) {
	     
	    return new Item(item.namn, item.namn2, item.sbl_price, item.pub_price, item.beer_id, item.count, item.price);

	}else{
	    return null;
	}
    },
    /*
     * Query the database. 
     * @function query
     * @param query 
     */
    query: function (query) {
	console.log("Model.query(): " + query);
	var _this = this;
        
	$.ajax({
            url: this._db_inventory,
	    type: "POST",
	    contentType: "application/json; charset=utf-8",
            dataType: 'json',
            asynch: false,
            success: function (data) {
		_this._drop();
		$.each(data.payload, function (key, item){
		    var newItem = _this._filter(query, item, _this);
		    if(newItem) {
			_this._itemList.push(newItem);
		    }
		});		
		
		console.log("Model.query().itemList: ", _this._itemList.length);
		_this.listUpdated.notify();
            },
            error : function(jqXHR, textStatus, errorThrown) {
                console.log('an error occurred!');
            }
        });

    },

    
    /*
     * Get an Item list
     * @function getItemList
     * @return {Item[]} a list with Items.
     */
    getItemList: function () {
        return [].concat(this._itemList);
    }
};
/*
 * The View. View presents the model and provides the UI events. The controller is attached to these events to handle the user interraction.
 * @class DataBaseModel
 * @param {DatabaseModel} model
 * @param {Object[]} elements
 * @constructor
 * Creates a DrinkView
 */
function DrinkView(model, elements) {
    this._model = model;
    this._elements = elements;
    this._currentQuery = "";

    this.inputModified = new Event(this);

    var _this = this;

    // attach model listener
    this._model.listUpdated.attach(function () {
        _this.refresh();
    });

    // listener to HTML input
    this._elements.input.on('input', function(e) {
	_this._setQuery($(this).val());
	_this.inputModified.notify();
    });
}

DrinkView.prototype = {
    _setQuery: function (newQuery) {
	this._currentQuery = newQuery;
    },
    /*
     * Shows the view.
     * @function show
     */ 
    show: function () {
	this.refresh();
    },

    /*
     * Refreshes the view. 
     * @function refresh
     */
    refresh: function () {
	var list = this._elements.list;
	var itemList = [];
	
	list.empty();
	
        list.append($('<table id="drink_table"></table>'));
        itemList = this._model.getItemList();

	console.log("View.refresh()", itemList.length);

	for(var i = 0; i < itemList.length; i++) {

            list.append($(
		'<tr>' +
                    '<td><button ' +
                    'class="item"' +
                    'onclick="addToCart(' + itemList[i].getId() + ')" ' +
                    'draggable="true">' +
                    itemList[i].getFullName() + 
                    '</button></td>' +
                    '<td>' + itemList[i].getPubPrice() + '</td>' +
                    '<td>' + itemList[i].getCount() + '</td>' +
                    '</tr>'));
        }
    },

    /*
     * Get the query from input
     * @function getQuery
     * @return {string} the query
     */
    getQuery: function () {
	return this._currentQuery;
    }
};


/*
 * The Controller. Controller responds to user actions and invokes changes on the model.
 * @class DrinkController
 * @param {DatabaseModel} model
 * @param {DrinkView} view
 * @constructor
 * Creates a DrinkController
 */
function DrinkController(model, view) {
    this._model = model;
    this._view = view;

    var _this = this;

    this._view.inputModified.attach(function () {
	_this.updateView();
    });
}

DrinkController.prototype = {
    /*
     * updates the view
     * @function updateView
     */
    updateView: function () {
	var query = this._view.getQuery();
	console.log("DrinkController.updateView: "+ query);
	this._model.query(query);
    }
};
/*
 * Main
 * @class Main
 * @constructor
 * Creates an MVC
 */
function Main() {
    this._model;
    this._view;
    this._controller;
}

Main.prototype = {
    /* 
     * Creates an MVC and shows the view. 
     * @function run
     */
    run: function() {
	this._model = new DatabaseModel();
	this._view = new DrinkView(this._model, {
	    'list': $('#drink_table'),
	    'input': $('#query')
	});
	this._controller = new DrinkController(this._model, this._view);
	this._view.show();
    }
}

/* 
 * Executes Main after the DOM is ready. 
 * @function ready
 */
$(function () {
    var main = new Main();
    main.run();
});

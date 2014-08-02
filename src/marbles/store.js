//= require ./core
//= require ./utils
//= require ./state

(function () {

"use strict";

/**
 * @memberof Marbles
 * @class
 * @param {*} id Anything serializable as JSON
 * @desc This class is meant to be sub-classed using Store.createClass
 */
var Store = Marbles.Store = function (id) {
	this.id = id;
	this.constructor.__trackInstance(this);

	this.__changeListeners = [];

	this.willInitialize.apply(this, Array.prototype.slice.call(arguments, 1));

	this.state = this.getInitialState();

	this.didInitialize.apply(this, Array.prototype.slice.call(arguments, 1));
};

Store.displayName = "Marbles.Store";

Marbles.Utils.extend(Store.prototype, Marbles.State, {
	/**
	 * @memberof Marbles.Store
	 * @instance
	 * @method
	 * @returns {Object} Initial state object
	 */
	getInitialState: function () {
		return {};
	},

	/**
	 * @memberof Marbles.Store
	 * @instance
	 * @method
	 * @desc Called before state is initialized
	 */
	willInitialize: function () {},

	/**
	 * @memberof Marbles.Store
	 * @instance
	 * @method
	 * @desc Called after state is initialized
	 */
	didInitialize: function () {},

	/**
	 * @memberof Marbles.Store
	 * @instance
	 * @method
	 * @desc Called when first change listener is added
	 */
	didBecomeActive: function () {},

	/**
	 * @memberof Marbles.Store
	 * @instance
	 * @method
	 * @desc Called when last change listener is removed
	 */
	didBecomeInactive: function () {},

	/**
	 * @memberof Marbles.Store
	 * @instance
	 * @method
	 * @param {Object} event
	 * @desc Called with Dispatcher events
	 */
	handleEvent: function () {}
});

// Call didBecomeActive when first change listener added
Store.prototype.addChangeListener = function () {
	Marbles.State.addChangeListener.apply(this, arguments);
	if (this.__changeListeners.length === 1) {
		this.didBecomeActive();
	}
};

// Call didBecomeInactive when last change listener removed
Store.prototype.removeChangeListener = function () {
	Marbles.State.removeChangeListener.apply(this, arguments);
	if (this.__changeListeners.length === 0) {
		this.didBecomeInactive();
	}
};

Store.__instances = {};

Store.__getInstance = function (id) {
	var key = JSON.stringify(id);
	return this.__instances[key] || new this(id);
};

Store.__trackInstance = function (instance) {
	var key = JSON.stringify(instance.id);
	this.__instances[key] = instance;
};

/**
 * @memberof Marbles.Store
 * @func
 * @param {Marbles.Store} store
 * @desc Give Store instance up for garbage collection
 */
Store.discardInstance = function (instance) {
	var key = JSON.stringify(instance.id);
	delete this.__instances[key];
};

/**
 * @memberof Marbles.Store
 * @func
 * @param {Store#id} id
 */
Store.addChangeListener = function (id) {
	var instance = this.__getInstance(id);
	return instance.addChangeListener.apply(instance, Array.prototype.slice.call(arguments, 1));
};

/**
 * @memberof Marbles.Store
 * @func
 * @param {Store#id} id
 */
Store.removeChangeListener = function (id) {
	var instance = this.__getInstance(id);
	return instance.removeChangeListener.apply(instance, Array.prototype.slice.call(arguments, 1));
};

/**
 * @memberof Marbles.Store
 * @prop {Number}
 */
Store.dispatcherIndex = null;

/**
 * @memberof Marbles.Store
 * @func
 * @param {Marbles.Dispatcher} dispatcher
 */
Store.registerWithDispatcher = function (dispatcher) {
	this.dispatcherIndex = dispatcher.register(function (event) {
		if (event.storeId && (!this.isValidId || this.isValidId(event.storeId))) {
			var instance = this.__getInstance(event.storeId);
			return Promise.resolve(instance.handleEvent(event));
		} else {
			return Promise.all(Object.keys(this.__instances).sort().map(function (key) {
				var instance = this.__instances[key];
				return new Promise(function (resolve) {
					resolve(instance.handleEvent(event));
				});
			}.bind(this)));
		}
	}.bind(this));
};

/**
 * @memberof Marbles.Store
 * @func
 * @param {Object} proto Prototype of new child class
 * @desc Creates a new class that inherits from Store
 * @example
 *	var MyStore = Marbles.Store.createClass({
 *		displayName: "MyStore",
 *
 *		getInitialState: function () {
 *			return { my: "state" };
 *		},
 *
 *		willInitialize: function () {
 *			// do something
 *		},
 *
 *		didInitialize: function () {
 *			// do something
 *		},
 *
 *		didBecomeActive: function () {
 *			// do something
 *		},
 *
 *		didBecomeInactive: function () {
 *			// do something
 *		},
 *
 *		handleEvent: function (event) {
 *			// do something
 *		}
 *	});
 *
 */
Store.createClass = function (proto) {
	var parent = this;
	var store = Marbles.Utils.inheritPrototype(function () {
		parent.apply(this, arguments);
	}, parent);

	store.__instances = {};

	if (proto.hasOwnProperty("displayName")) {
		store.displayName = proto.displayName;
		delete proto.displayName;
	}

	Marbles.Utils.extend(store.prototype, proto);

	function wrappedFn(name, id) {
		var instance = this.__getInstance(id);
		return instance[name].apply(instance, Array.prototype.slice.call(arguments, 2));
	}

	for (var k in proto) {
		if (proto.hasOwnProperty(k) && k.slice(0, 1) !== "_" && typeof proto[k] === "function") {
			store[k] = wrappedFn.bind(store, k);
		}
	}

	return store;
};

})();

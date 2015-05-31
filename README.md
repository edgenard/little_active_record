# Little Active Record
A project to better understand the magic behind the Rails library Active Record and practice metaprogramming in Ruby

## How to use

### Set up a connection to the DB
You will need something that connects to the database. I used the [sqlite3 gem](https://github.com/sparklemotion/sqlite3-ruby) to allow me to write SQL queries in Ruby.  I used a `DBConnection` class that set up the connection the DB and would reset the connection if necessary. It also wrapped some of the methods provided by the gem to  make it easier to debug by printing out the SQL query I was sending. 

### Setup the models
#### Models inherit from `SQLObject`. 
This is like inheriting from `ActiveRecord::Base` but you must call the class method `finalize` this is a bit of hack but necessary to set up the getters and setters based on column names from the table the model refers to. 

**NB:** I use the `ActiveSupport\inflector` library to infer the table names from the model names so you will need to set table a name for any model whose plural isn’t straightforward. For example: a  model class named `Human` gets pluralized to “humen”. So you will have to manually set the table name to `humans`. If you get an error about not being able to find a table name in the DB it might be because of that. 

#### Common Methods
* `::all` - gets all the records of that model from DB.
* `::find(id)` - returns an instance of the model that has that id from the DB.
* `::new` - creates a new instance of the of the model. Checks that attributes passed correspond to columns in the database.
* `#save` - saves the a record to DB, calls `#insert` or `#update` depending on whether or not the model already has an id. 
* `::where(parameters)` - takes a hash of parameters and values. Parameters must be column names and multiple parameters get joined with `AND`. 
* `::belongs_to(name, options)` - Sets up an association creating the method `#name` based on the name argument passed to it that returns an instance of model’s “owner”. Just like Active Record it uses sensible defaults for the foreign key, class name and primary key. You can override the defaults by passing in an `options` hash as the second arguments. 
* `::has_many(name, options)` - The same as `belongs_to` except it returns an array instances instead of a single instance of the association.
* `::has_one_through(name, through_name, source_name)` - connects two `belongs_to` associations. Like Active Record the `through_name` must be an existing `belongs_to` association on the current model and the `source_name` must be an existing `belongs_to` association on the model of the `through_name`. 


## Setting up associations. 
The most interesting part of this little project was setting up ’::belongs_to` and `::has_many`. To mimic Active Record I had to  offer sensible defaults while allowing for overrides when necessary. 

I used classes to store the default values. This separated setting up the associations from providing default values. When the association methods where called I created a new instance of either `BelongsToOptions` or `HasManyOptions` to take care of the defaults. If had left this up to the `Associatable` module every time I needed to make a change to how the values were implemented I would have to do this in several places. 

I used the values from classes to set up the methods on the instance of the object using `::define_method`.

## Todo
* Validations
* An `includes` method that does prefetching. 
* `::has_many :through`. It should handle it going both ways `belongs_to => has_many` and `has_many => belongs_to`

 


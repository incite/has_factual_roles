# has_factual_roles

... is a plugin for adding "roles" to a **Ruby** class (not necessarily ActiveRecord).

# So why another roles plugin?

I looked for a roles plugin that could give me something like "user X is an admin IF condition Y is satisfied", configurable through a nice looking DSL. Plugins that you can configure through DSLs are made of win.

# Installation

From inside your rails app

    ./script/plugin install git://github.com/incite/has_factual_roles.git
    
# Usage

Say you have an online bookstore where any user can become an author (hah!), thus attaining the "author" status for books he creates. Users can also collaborate with others and help them out writing a chapter or two for their books, becoming "contributors" in doing so. And they can also be just "user" if they're just going around reading stuff.

But let's say that after a while and a lot of criticism, an author breaks down in tears and decides to take his books down. He obviously shouldn't be considered an author anymore if he does so, as he has no books as far as the system is concerned. However, he's happy for his contributions to stay where they are, as they don't carry his name.

So a user:

- is only an author **if** he has one or more books that belong to him.
- is only a contributor **if** he contributed to one or more books.
- is just a user if he has no books and no contributions

Assuming the following classes and relationships

    class Book
      belongs_to  :author
      has_many    :contributions
    end
    
    class Contribution
      belongs_to  :user
      belongs_to  :book
    end
    
    class User
      has_many    :books
      has_many    :contributions
    end
    
You would define your roles like that

    class User
      has_many    :books
      has_many    :contributions
      
      has_factual_roles do
        is :author,       :if => 'not books.empty?'
        is :contributor,  :if => 'not contributions.empty?'
        is :user          :if => 'contributions.empty? and books.empty?'
        roles_order :author, :contributor, :user
      end
    end
    
**:if** will accept a symbol for a method that will get invoked on an instance (returns true, role applies), or a string that will be eval'ed against an instance.

**roles_order** states, from left to right, what's the "higher" role. In this example that wouldn't make any difference, but if you want to establish any sort of hierarchy, that's the way to go.

The following methods will be available once you declare your roles:

    >> user = User.create
    => #<User id: 1>
    >> user.user?
    => true
    >> user.books.create
    => #<Book id: 1, user_id: 1>
    >> user.author?
    => true
    >> user.contributions.create
    => #<Contribution id: 1, user_id: 1, book_id: nil>
    >> user.contributor?
    => true
    >> user.roles
    => [:user, :author, :contributor]
    >> user.major_role
    => :author

# PS

There's a FactualRolesController module in the same library that's supposed to be use with ActionController for requiring roles in order to execute certain actions. That's heavily under development, and I'll leave it there in case someone decides to improve on it. I **do not** recommend anyone use it right now.

# License

See MIT-LICENSE.

# Author

Julio Cesar Ody - julio.ody@nexuspoint.com.au
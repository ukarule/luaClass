--[[
luaClass.

this is utf-8 encoded document.

http://github.com/ukarule/luaClass

]]



require "luaClass"



-- Create a base class example with instance methods definition.
class({}, 'cores.Object'):methods {
	initailze = function(self, ...)
		print('cores.Object.initialze()')
	end
	
	, testMethod = function()
		error('if this method is called, it is an error.')
	end
}

assert(cores.Object ~= nil, 'The class is not created in _G.')



-- class function definition example.
cores.Object.classFunction = function()
	return 'this is classFunction. not instance method.'
end

function cores.Object.classFunction()
	return 'this is classFunction, too. not instance method.'
end




-- Changing methods
cores.Object:methods {
	testMethod = function()
		return 'this is a valid method.'
	end
	
	, setName = function(self, name_)
		self.name = name_
	end
	
	, getName = function(self)
		return self.name
	end
}




-- Create a class 'tests.ParentClass' inherit from cores.Object.
class(cores.Object, 'tests.ParentClass'):methods {
	initailze = function(self, ...)
		super.initailze(self)	--call super method
		print('tests.ParentClass.initialze()')
	end

	, testMethod = function(self)
		return super:testMethod()
	end
}



--	Just create class "tests.ChildClass"
tests.ParentClass:subclass('tests.ChildClass')





local obj = cores.Object()
local obj2 = obj
assert(obj == obj2, 'must same object.')


local parentInstance = tests.ParentClass()
assert(parentInstance:testMethod() == 'this is a valid method.', 'method not changed.')


parentInstance.name = 'The Parent'
assert(parentInstance:getName() == 'The Parent', 'maybe polymorphism problem.')


local childInstance = tests.ChildClass()
childInstance:setName('The Child')
assert(childInstance:getName() == 'The Child', 'maybe polymorphism problem.')

obj = nil
obj2 = nil
parentInstance = nil
childInstance = nil

--todo gc status

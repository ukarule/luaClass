--[[
luaClass.

this is utf-8 encoded document.

http://github.com/ukarule/luaClass	

@todo	refactoring super keyword
@todo	dynamic or strict mode class
@todo	automatic getter/settter at strict class
@todo	variable class tools
@todo	__xxx metamethods automatic setting.
@todo	public, private is needed?
@todo	always for simple using
]]





---	base_ 테이블안에, strPath_ 의 경로가 없으면 만들어서 반환.
--	@example	local parent = getValidClassPath(getfenv(0), 'grandma.ma.child')	--글로벌테이블의 _G.grandma.ma.child 테이블을 반환. 없으면 모두 생성한 후 반환.
local function getValidClassPath(base_, strPath_)
	--local nowPath
	strPath_:gsub('([^\.]+)', function(name_)
		-- __tostring 에서 사용하기 위해, 현재 경로를 잠시 저장함.
		--nowPath = nowPath and string.format('%s.%s', nowPath, name_) or name_
		if not base_[name_] then
			base_[name_] = {}
			--rawset(base_, name_, {})
			--local pathDesc = string.format('[%s] class path.', nowPath)
			--setmetatable(base_[name_], {
				-- class path 는 직접 변경 불가능하도록 설정.
				--__newindex = function()	error('Forbid changing "class path" direct.', 2) end
				--, __tostring = function() return pathDesc end
			--})
		end
		base_ = base_[name_]
	end)
	return base_
end


local temp = {}
assert(getValidClassPath(temp, '__test__') == temp.__test__)
assert(getValidClassPath(temp, '__test__.TEST') == temp.__test__.TEST)




---	클래스를 생성. 반환도 하긴 하는데, 일단 이 함수를 호출만 하면, 클래스를 생성함.
--	@param	superClass_	상속할 superClass 를 넣어주고, 절대 nil 이면 안된다. 아무것도 상속하지 않는 경우, {} 빈테이블을 넣어준다.
function class(superClass_, newClassPath_)
	--	기본 파라미터 체크.
	assert(superClass_, 'superClass_ must not nil. ')
    assert(newClassPath_ and type(newClassPath_) == 'string' and #newClassPath_ > 0, 'Invalid newClassPath_: ' .. tostring(newClassPath_))
	
	--	일단, 간단하게, _G 에 새로운 클래스의 path 자리에 빈 테이블을 생성한다.
    local newClass = getValidClassPath(getfenv(0), newClassPath_)
	
	--	새로 생성한 테이블이, 다른 형으로 이미 있는 상태라면, 클래스가 두번 선언되었다든지 여튼 문제가 있으므로...
    assert(type(newClass) == 'table', 'Already exist class path: ' .. tostring(newClassPath_))
	
	
	-- 일단 클래스 이름 설정
	newClass.className = newClassPath_
	
	-- 인스턴스 메소드들에 모두 할당할 env 변수. 현재는 super 키워드만 사용.
	newClass.methodEnv = {super = superClass_.__index}
	setmetatable(newClass.methodEnv, {__index = _G, __mode='v'})
	
	-- "클래스" 테이블을 그 "클래스" 에서 생성한 "인스턴스" 테이블의 메타테이블로 사용한다. 그럼므로 newClass.__index 에 인스턴스 메소드를 저장한다.
	newClass.__index = {
		class = newClass
	}
	
	-- newClass.__index 를 참조했는데도 메소드가 없을 경우, superClass_.__index 로 한 단계씩 타고 올라간다. (메소드 상속의 실질적 구현)
	setmetatable(newClass.__index, {
		__newindex = function() error('Forbid direct changing class.__index table.', 2) end
		, __index = superClass_.__index or nil
		, __mode='v'
	})
	
	--	superClass_ 가 있으면, superClass_ 의 메타테이블을 곧바로 상속하고,
	--	superClass_ 가 없더라도, 가장 기본적인 클래스 함수들은 사용 가능 하도록 넣어 준다.
	setmetatable(newClass, getmetatable(superClass_) or {
		---	새로운 인스턴스를 생성하려면, 그냥 클래스를 함수처럼 호출해 버리면 된다.
		--	@example	local instance = MyClassName() --MyClassName 클래스의 새로운 인스턴스를 생성하면서 초기화 함수를 호출하고 인스턴스를 반환.
		--	@todo	클래스 생성시, dynamic 과 strict 형태로 구분하여 생성할 수 있도록 도구를 제공하는 것은 어떤가?
		__call = function(class_, ...)
			assert(class_ and class_.__index, 'Invalid class_: ' .. tostring(class_))
			
			local instance = {}
			
			-- 인스턴스는 단지 메타테이블이 클래스인 테이블 이다.
			setmetatable(instance, class_)
			
			if instance.initailze then
				instance:initailze(...)
			end
			
			return instance
		end
		
		, __index = {
			subclass = class
			
			---	클래스의 인스턴스 함수들을 설정할 때 사용하는 함수.
			--	@example	MyClass:methods{myMethod=function(self) end, ...}	-- MyClass 라는 클래스의 인스턴스 메소드 myMethod 를 추가하였다.
			, methods = function(class_, methods_)
				for methodsName, method in pairs(methods_) do
					assert(type(method) == 'function', string.format('"methods_" parameter must contains only methods: [%s] class, [%s] method name, [%s]', tostring(class_.className), tostring(methodName), tostring(method)))
					setfenv(method, class_.methodEnv)
					rawset(class_.__index, methodsName, method)	-- 기본적으로 클래스 생성 후, 클래스 테이블이 잠기므로 rawset() 으로 설정
				end
			end
		}
		
		, __tostring = function(class_) return class_.className end
	})
	
	
	print(string.format('Created class: %s', newClassPath_))
    return newClass
end

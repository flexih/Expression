# Expression

Statement runtime bridges with Objective C, which is faster than JavaScript Core.



> Operator

```c
+ - ~ * / & | && || % < <= > >= == != ?: ( )
```



> Operand

```c
100, 3.14, '万', true, false, max(), min(), func()
```



> Operand Extend

```objective-c
'string'
any + 'string'=any.description+'string' //@any, number, string
obj1 == obj2 //[obj1 isEqual:obj2]
obj1 != obj2 //![obj1 isEqual:obj2]
```



> switch-case

```c
switch(expression)
case constNumber:
    expression
case constString:
    expression
default:
    expression
```



> if-else

```c
if (expression)
    expression
elif (expression)
    expression
else
    expression
```

_switch-case_ , _if-else_ can't contains each other.



> Assignment

```objective-c
variable.assign(value)
#id.setVisibility(true) //#id.visibility=true，equivalent [idObj setVisibility:true]
```



> Internal functions

```c
min(a,b)
max(a, b)
split('str', 'seperator', index) //string
len(arg) //array.count, dictionary.count, string.length
ele(array, index) //array[index]
get(dict, key) //dict[key]
dict(key1, value1, key2, value2) //dict
array(element1, element2) //array
round(number) //round()
ceil(number) //ceil()
floor(number) //floor
decimal(decimal, number) //"%.number", decimal
joined(array, 'seperator')
onePixel() //1px on any device
isiOS() //true on iOS, false on Android
isAndroid() //true on Android, false on iOS
truncate(string, count, token) //if string.length>count string=string[0:count]+token
```



> Font

```xml
Helvetica 30 italic
System 30 italic
30 italic
30
```



> String

```xml
abc{expression}
{expression}
abc{expression1}efg{expression2}
```

{expression} in string

`string`, `url`, `alignment`, `breakmode`, etc. value of expression expected to be string



> Color

```xml
rgba(r,g,b,a) //Color(r/255.0, g/255.0, b/255.0, a)
rgb(r,g,b)
#ffffff
#fff
white
```

_literals_

`black` `darkGray` `lightGray` `white` `gray` `red` `green` `blue` `cyan` `yellow` `magenta` `orange` `purple` `brown` `clear`



> Coordinate

```xml
<View left="previous.right+10" right="next.left-10"/>
```



> Size

```xml
<Label width="auto" height="100%">
<View width="auto" height="width">
    <UIView/>
</View>
```



> Examples

```c
a+3
max(b*3, 10)
a||b
a>10000?a/10000.0+'万':(a==0?:'评论':a)
```


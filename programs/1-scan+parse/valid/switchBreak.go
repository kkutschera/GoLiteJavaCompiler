// valid break within a swtich statement
package test

var x = 4

func main(){
	switch x {
	case 2:
		println("hi")
		break
	default:
		println("hello")
	}
}
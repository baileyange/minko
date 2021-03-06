package aerys.minko.scene.node
{
	import aerys.minko.scene.SceneIterator;
	import aerys.minko.scene.action.IAction;

	import flash.events.IEventDispatcher;

	/**
	 * The IScene is the the most basic definition of a scene graph node.
	 *
	 * @author Jean-Marc Le Roux
	 *
	 */
	public interface IScene extends IEventDispatcher
	{
		function get name()		: String;
		function set name(value : String) : void;

		function get parents()	: SceneIterator;
		function get actions()	: Vector.<IAction>;
	}
}
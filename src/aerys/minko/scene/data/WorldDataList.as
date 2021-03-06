package aerys.minko.scene.data
{
	import aerys.minko.type.Factory;

	import flash.utils.Dictionary;

	public class WorldDataList implements IWorldData
	{
		protected var _objects		: Vector.<IWorldData>;

		public function get length() : uint
		{
			return _objects.length;
		}

		public function set length(v : uint) : void
		{
			if (v != _objects.length)
			{
				_objects.length = v;
			}
		}

		public function WorldDataList(styleId : int = -1)
		{
			_objects = new Vector.<IWorldData>();
		}

		public function setDataProvider(styleStack	: StyleData,
										transformData	: TransformData,
										worldData	: Dictionary) : void
		{
			for each (var dataObject : IWorldData in _objects)
				dataObject.setDataProvider(styleStack, transformData, worldData);
		}

		public function invalidate() : void
		{
			for each (var dataObject : IWorldData in _objects)
				dataObject.invalidate();
		}

		public function reset() : void
		{
			for each (var dataObject : IWorldData in _objects)
				dataObject.reset();
		}

		public function getItem(i : uint) : IWorldData
		{
			return _objects[i];
		}

		public function setItem(i : uint, value : IWorldData) : void
		{
			_objects[i] = value;
		}

		public function push(v : IWorldData) : void
		{
			_objects.push(v);
		}

		public function pop() : IWorldData
		{
			return _objects.pop();
		}

		public function clone() : WorldDataList
		{
			var newStyleObjList : WorldDataList = Factory.getFactory(WorldDataList).create(true)
												  as WorldDataList;

			newStyleObjList._objects	= _objects.concat();

			return newStyleObjList;
		}

	}
}
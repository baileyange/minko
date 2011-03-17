package aerys.minko.scene.group
{
	import aerys.minko.query.IScene3DQuery;
	import aerys.minko.query.rendering.RenderingQuery;
	import aerys.minko.scene.AbstractScene3D;
	import aerys.minko.scene.IScene3D;
	
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	/**
	 * The Object3DContainer provides a basic support for Object3D grouping. Such
	 * groups can be used to provide local z-sorting or apply a common 3D transform.
	 * An Object3DContainer can contain any object implementing the IChild3D interface,
	 * including Object3D or even Object3DContainer object.
	 *
	 * @author Jean-Marc Le Roux
	 * @see aerys.minko.scene.containers.IContainer3D
	 * @see aerys.minko.scene.Object3D
	 * @see aerys.minko.scene.IChild3D
	 */
	public dynamic class Group3D extends Proxy implements IGroup3D
	{
		private static var _id		: uint				= 0;
		
		private var _name			: String			= null;
		
		private var _visiting		: IScene3D			= null;
		
		private var _toRemove		: Vector.<IScene3D>	= new Vector.<IScene3D>();
		private var _toAdd			: Vector.<IScene3D>	= new Vector.<IScene3D>();
		private var _toAddAt		: Vector.<int>		= new Vector.<int>();
		
		private var _children		: Vector.<IScene3D>	= null;
		
		private var _numChildren	: int				= 0;
		
		public function get name()					: String				{ return _name; }
		
		protected function get rawChildren() 		: Vector.<IScene3D> 	{ return _children; }
		
		protected function set rawChildren(value 	: Vector.<IScene3D>) : void
		{
			_children = value;
			_numChildren = _children.length;
		}
		
		/**
		 * The number of children.
		 */
		public function get numChildren() : uint
		{
			return _numChildren;
		}
		
		public function Group3D(...children)
		{
			super();
			
			_name = AbstractScene3D.getDefaultSceneName(this);

			initialize(children);
		}
		
		private function initialize(children : Array) : void
		{
			while (children.length == 1 && children[0] is Array)
				children = children[0];
			
			_numChildren = children.length;
			_children = _numChildren ? Vector.<IScene3D>(children)
									 : new Vector.<IScene3D>();
		}
		
		public function contains(scene : IScene3D) : Boolean
		{
			return getChildIndex(scene) >= 0;
		}
		
		public function getChildIndex(child : IScene3D) : int
		{
			for (var i : int = 0; i < _numChildren; i++)
				if (_children[i] === child)
					return i;
			
			return -1;
		}
		
		public function getChildByName(name : String) : IScene3D
		{
			for (var i : int = 0; i < _numChildren; i++)
				if (_children[i].name === name)
					return _children[i];
			
			return null;
		}
		
		/**
		 * Add a child to the container.
		 *
		 * @param	myChild The child to add.
		 */
		public function addChild(scene : IScene3D) : IScene3D
		{
			if (!scene)
				throw new Error();
			
			if (_visiting)
			{
				_toAdd.push(scene);
				_toAddAt.push(-1);
			}
			else
			{
				_children.push(scene);
				++_numChildren;
			}
			
			//scene.added(this);
			
			return scene;
		}
		
		public function addChildAt(scene : IScene3D, position : uint) : IScene3D
		{
			if (!scene)
				throw new Error();
			
			var numChildren : int = _children.length;
			
			if (_visiting)
			{
				_toAdd.push(scene);
				_toAddAt.push(position);
				
				return scene;
			}
			
			if (position >= numChildren)
				return addChild(scene);
			
			for (var i : int = numChildren; i > position; --i)
				_children[i] = _children[int(i - 1)];
			_children[position] = scene;
			
			++_numChildren;
			//myScene.added(this);
			
			return scene;
		}
		
		/**
		 * Remove a child from the container.
		 *
		 * @param	myChild The child to remove.
		 * @return Whether the child was actually removed or not.
		 */
		public function removeChild(child : IScene3D) : IScene3D
		{
			var numChildren : int = _children.length;
			var i : int	= 0;

			while (i < numChildren && _children[i] !== child)
				++i;
			
			if (i >= numChildren)
				return null;
			
			return removeChildAt(i);
		}
		
		public function removeChildAt(position : uint) : IScene3D
		{
			var removed 	: IScene3D 	= null;
	
			if (position < _numChildren)
			{
				removed = _children[position];
				
				if (_visiting)
				{
					_toRemove.push(removed);
					
					return removed;
				}
				
				while (position < _numChildren - 1)
					_children[position] = _children[int(++position)];
				_children.length = --_numChildren;
				
				//removed.removed(this);
			}
			
			return removed;
		}
		
		public function removeAllChildren() : uint
		{
			//var i : int = _numChildren - 1;
			
			/*while (i >= 0)
			{
				//_children[i].removed(this);
				_children.length = i;
				--i;
			}*/
			
			var numChildren : int = _numChildren;
			
			if (_visiting)
			{
				while (numChildren)
					_toRemove.push(_children[int(numChildren--)]);
				
				return _numChildren;
			}
			else
			{
				_children.length = 0;
				_numChildren = 0;
			}
			
			return numChildren;
		}
		
		public function getChildAt(myPosition : uint) : IScene3D
		{
			return myPosition < _numChildren ? _children[myPosition] : null;
		}
		
		public function swapChildren(myChild1	: IScene3D,
									 myChild2	: IScene3D) : Boolean
		{
			var id1	: int 	= getChildIndex(myChild1);
			var id2 : int	= getChildIndex(myChild2);
			
			if (id1 == -1 || id2 == -1)
				return false;
			
			var tmp : IScene3D = _children[id2];
			
			_children[id2] = _children[id1];
			_children[id1] = tmp;
			
			return true;
		}
		
		public function getDescendantByName(name : String) : IScene3D
		{
			var descendant 	: IScene3D 	= getChildByName(name);
			var numChildren	: int 		= numChildren;
			
			for (var i : int = 0; i < numChildren && !descendant; ++i)
			{
				var childGroup : IGroup3D = _children[i] as IGroup3D;
				
				if (childGroup)
					descendant = childGroup.getDescendantByName(name);
			}
			
			return descendant;
		}

		/**
		 * Render child nodes.
		 *
		 * @param myGraphics The Graphics3D object that describes the frame being rendered.
		 */
		public function accept(query : IScene3DQuery) : void
		{
			if (query is RenderingQuery)
				acceptRenderingQuery(query as RenderingQuery);
			else
				visitChildren(query);
		}
		
		protected function acceptRenderingQuery(query : RenderingQuery) : void
		{
			visitChildren(query);
		}
		
		protected function visitChildren(query : IScene3DQuery) : void
		{
			var numChildren : int = _numChildren;
			var i 			: int = 0;
			
			// lock
			_visiting = this;
			
			for (i = 0; i < numChildren; ++i)
				childVisited(_children[i], query);
			
			// unlock
			_visiting = null;
			
			if (_toRemove.length)
			{
				var numRemoved : int = _toRemove.length;
				
				for (i = 0; i < numRemoved; ++i)
					removeChild(_toRemove[i]);
				
				_toRemove.length = 0;
			}
			
			if (_toAdd.length)
			{
				var numAdded : int = _toAdd.length;
				
				for (i = 0; i < numAdded; ++i)
				{
					var position : int = _toAddAt[i];
					
					if (position == -1)
						addChild(_toAdd[i]);
					else
						addChildAt(_toAdd[i], position);
				}
				
				_toAdd.length = 0;
			}
		}
		
		protected function childVisited(child 	: IScene3D,
									  	visitor : IScene3DQuery) : void
		{
			visitor.query(child);
		}
		
		override flash_proxy function getProperty(name : *) : *
		{
			return parseInt(name) == name ? getChildAt(name) : getChildByName(name);
		}
		
		override flash_proxy function getDescendants(name : *) : *
		{
			return getDescendantByName(name);
		}
		
		override flash_proxy function nextNameIndex(index : int) : int
		{
			return index < numChildren ? index + 1 : 0;
		}
		
		override flash_proxy function nextName(index : int) : String
		{
			return String(index - 1);
		}
		
		override flash_proxy function nextValue(index : int) : *
		{
			return _children[int(index - 1)];
		}
	}
}
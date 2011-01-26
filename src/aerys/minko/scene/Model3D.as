package aerys.minko.scene
{
	import aerys.minko.effect.Effect3DStyle;
	import aerys.minko.effect.IEffect3D;
	import aerys.minko.effect.IEffect3DPass;
	import aerys.minko.effect.IEffect3DStyle;
	import aerys.minko.effect.IStyled3D;
	import aerys.minko.effect.basic.BasicEffect3D;
	import aerys.minko.effect.basic.BasicStyle3D;
	import aerys.minko.ns.minko;
	import aerys.minko.query.IScene3DQuery;
	import aerys.minko.query.RenderingQuery;
	import aerys.minko.render.IRenderer3D;
	import aerys.minko.render.state.RenderState;
	import aerys.minko.scene.material.IMaterial3D;
	import aerys.minko.scene.mesh.IMesh3D;
	import aerys.minko.transform.Transform3D;
	import aerys.minko.transform.TransformManager;
	import aerys.minko.transform.TransformType;
	import aerys.minko.type.math.Matrix4x4;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;

	public class Model3D extends AbstractScene3D implements IScene3D, IObject3D, IStyled3D
	{
		use namespace minko;
		
		private var _mesh		: IMesh3D				= null;
		private var _material	: IMaterial3D			= null;
		private var _transform	: Transform3D			= new Transform3D();
		private var _visible	: Boolean				= true;
		private var _effects	: Vector.<IEffect3D>	= Vector.<IEffect3D>([new BasicEffect3D()]);
		private var _style		: IEffect3DStyle		= new Effect3DStyle();
		private var _toScreen	: Matrix4x4				= new Matrix4x4();
		
		public function get transform() 	: Transform3D			{ return _transform; }
		public function get mesh()			: IMesh3D				{ return _mesh; }
		public function get material()		: IMaterial3D			{ return _material; }
		public function get visible()		: Boolean				{ return _visible; }
		public function get effects()		: Vector.<IEffect3D>	{ return _effects; }
		public function get style()			: IEffect3DStyle		{ return _style; }
		
		public function set mesh(value : IMesh3D) : void
		{
			_mesh = value;
		}
		
		public function set material(value : IMaterial3D) : void
		{
			_material = value;
		}
		
		public function set visible(value : Boolean) : void
		{
			_visible = value;
		}
		
		public function Model3D(mesh 	 : IMesh3D		= null,
								material : IMaterial3D	= null)
		{
			super();
			
			_mesh = mesh;
			_material = material;
		}
		
		override public function accept(query : IScene3DQuery) : void
		{
			if (query is RenderingQuery)
				draw(query as RenderingQuery);
		}
		
		protected function draw(query : RenderingQuery) : void 
		{
			var transform 	: TransformManager 	= query.transform;
			
			transform.push(TransformType.WORLD);
			transform.world.multiply(_transform);
			transform.getLocalToScreen(_toScreen);
			
			_style.set(BasicStyle3D.WORLD, transform.world)
				  .set(BasicStyle3D.VIEW, transform.view)
				  .set(BasicStyle3D.PROJECTION, transform.projection)
				  .set(BasicStyle3D.LOCAL_TO_SCREEN, _toScreen);
			query.style = _style.override(query.style);
			
			_mesh && query.query(_mesh);
			_material && query.query(_material);
			
			var numEffects : int = _effects.length;
			
			for (var i : int = 0; i < numEffects; ++i)
			{
				query.beginEffect(_effects[i]);
				query.draw(_mesh.vertexStream, _mesh.indexStream);
				query.endEffect();
			}
			
			query.style = _style.override();
			
			transform.pop();
		}
	}
}
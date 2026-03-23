drop function if exists coste_viaje;

delimiter //

create function coste_viaje(p_id_pedido int)
returns decimal(10,2)
deterministic
begin
    declare v_coste decimal(10,2);

    select km_total * precioKm
    into v_coste
    from VIAJE
    where PEDIDO_id_pedido = p_id_pedido;

    return v_coste;
end //

delimiter ;

select coste_viaje(1);


drop function if exists total_viajes_empleado;

delimiter //

create function total_viajes_empleado(p_dni varchar(9))
returns int
deterministic
begin
    declare v_total int;

    select count(*)
    into v_total
    from VIAJE
    where EMPLEADOS_DNI = p_dni;

    return v_total;
end //

delimiter ;

select
    DNI,
    nombre,
    apellidos,
    carnet,
    total_viajes_empleado(DNI) as total_viajes
from EMPLEADOS
order by total_viajes desc;

drop trigger if exists comprobar_km_viaje;

delimiter //

create trigger comprobar_km_viaje
before insert on VIAJE
for each row
begin
    if new.km_total < 0 then
        signal sqlstate '45000'
        set message_text = 'los km no pueden ser negativos';
    end if;
end //

delimiter ;

insert into PEDIDO (id_pedido, Numero_TLF, fecha_pedido)
values (100003, '600123456', '2026-03-01');

insert into VIAJE (
    PEDIDO_id_pedido,
    fecha_inicio,
    fecha_fin,
    km_total,
    precioKm,
    EMPLEADOS_DNI,
    VEHICULO_matricula
)
values (100002,'2026-03-01','2026-03-02',10,2,'14353902Q','2684-MNP');


select *
from VIAJE
where PEDIDO_id_pedido = 100002;



drop trigger if exists evitar_viaje_duplicado;

delimiter //

create trigger evitar_viaje_duplicado
before insert on VIAJE
for each row
begin
    if exists (
        select *
        from VIAJE
        where PEDIDO_id_pedido = new.PEDIDO_id_pedido
    ) then
        signal sqlstate '45000'
        set message_text = 'ya existe un viaje para este pedido';
    end if;
end //

delimiter ;

-- primer insert (funciona)
insert into VIAJE (
    PEDIDO_id_pedido, fecha_inicio,
    fecha_fin,
    km_total,
    precioKm,
    EMPLEADOS_DNI,
    VEHICULO_matricula
)
values (
    100001,
    '2026-03-01',
    '2026-03-02',
    10,
    2,
    '993465631',
    '1234ABC'
);

-- segundo insert (debe fallar)
insert into VIAJE (
    PEDIDO_id_pedido,
    fecha_inicio,
    fecha_fin,
    km_total,
    precioKm,
    EMPLEADOS_DNI,
    VEHICULO_matricula
)
values (
    100003,
    '2026-03-03',
    '2026-03-04',
    20,
    2,
    '14353902Q',
    '2684-MNP'
);

select
    p.id_pedido,
    p.Numero_TLF,
    p.fecha_pedido,
    v.km_total,
    v.precioKm
from PEDIDO p
left join VIAJE v
    on p.id_pedido = v.PEDIDO_id_pedido
where p.id_pedido = 100003;


delimiter //
create procedure mostrar_info_pedido(in p_id_pedido int)
begin
   select
       p.id_pedido,
       p.Numero_TLF,
       s.precio_base as coste_servicio,   
       coste_viaje(p.id_pedido) as coste_viaje, 
       (s.precio_base + coste_viaje(p.id_pedido)) as coste_total  
   from PEDIDO p
   join Detalle_pedido dp
       on p.id_pedido = dp.PEDIDO_id_pedido
   join SERVICIO s
       on dp.SERVICIO_id_servicio = s.id_servicio 
   where p.id_pedido = p_id_pedido;
end //
delimiter ;


call mostrar_info_pedido(3);


create procedure mostrar_detalle_pedido(in p_id_pedido int)
begin
   select
       p.id_pedido,
       p.fecha_pedido,
       s.nombre_servicio,
       concat(e.nombre, ' ', e.apellidos) as empleado
   from PEDIDO p
   join Detalle_pedido dp
       on p.id_pedido = dp.PEDIDO_id_pedido
   join SERVICIO s
       on dp.SERVICIO_id_servicio = s.id_servicio
   join EMPLEADOS e
       on dp.EMPLEADOS_DNI = e.DNI
   where p.id_pedido = p_id_pedido;
end //
delimiter ;

call mostrar_detalle_pedido(1053);



delimiter //
create procedure mostrar_viajes_empleado(in p_dni varchar(9))
begin
   select
       e.DNI,
       concat(e.nombre, ' ', e.apellidos) as empleado,
       v.PEDIDO_id_pedido,
       v.fecha_inicio,
       v.fecha_fin,
       v.km_total,
       v.precioKm
   from EMPLEADOS e
   join VIAJE v
       on e.DNI = v.EMPLEADOS_DNI
   where e.DNI = p_dni;
end //
delimiter ;


call mostrar_viajes_empleado('14353902Q');
